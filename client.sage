import argparse
import socket
import json
import base64
import pickle

from common import *

# Define available operations
parser = argparse.ArgumentParser()
parser.add_argument('-op', '--operation', required=True, metavar='OP', choices=['register', 'login'], help='...')
args = parser.parse_args()

def init_socket():
    server_address = ('localhost', 10001)
    print('connecting to {} port {}'.format(*server_address))
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(server_address)
    return sock

def register_user(sock):

    # TODO: ask user for pwd
    pw = b'pwd123'

    # choose a private and a public key
    prv_u = Integer(Fn.random_element())
    pub_u = prv_u * G

    # choose random r
    r = Integer(Fn.random_element())

    # compute alpha
    alpha = hp(pw) * r

    # send alpha to server
    x, y = alpha.xy()
    send(sock, {'op': 'register', 'alpha_x': int(x), 'alpha_y': int(y)})

    # receive beta and pub_s from server
    data = sock.recv(1024)
    data = json.loads(data)

    beta = E(data['beta_x'], data['beta_y'])
    pub_s = E(data['P_s_x'], data['P_s_y'])

    # compute rw
    rw = h(pw + ecp2b(beta * r.inverse_mod(n)))

    # encrypt and authenticate prv_u, pub_u and pub_s
    c_data = pickle.dumps((prv_u, pub_u, pub_s))
    c = auth_enc(rw, c_data)

    # send c and pub_u to the server
    x, y = pub_u.xy()
    send(sock, {
        'c': base64.b64encode(c).decode(),
        'P_u_x': int(x),
        'P_u_y': int(y)
    })

def login(sock):

    # TODO: ask user for pwd
    pw = b'pwd123'

    # choose random r and x_u
    r = Integer(Fn.random_element())
    x_u = Integer(Fn.random_element())

    # compute alpha and X_u
    alpha = hp(pw) * r
    X_u = x_u * G

    # sending alpha and X_u to the server
    data = {'op': 'login'}
    data.update(ecp2j(alpha, 'alpha'))
    data.update(ecp2j(X_u, 'X_u'))
    send(sock, data)

    # receive beta, X_s, c and A_s
    data = recv_json(sock)
    beta = j2ecp(data, E, 'beta')
    X_s = j2ecp(data, E, 'X_s')
    c = base64.b64decode(data['c'].encode())
    A_s = base64.b64decode(data['A_s'].encode())

    # check beta belongs to the curve
    x, y = beta.xy()
    if not E.is_on_curve(x, y):
        abort()

    # compute rw and decrypt c
    rw = h(pw + ecp2b(beta * r.inverse_mod(n)))
    prv_u, pub_u, pub_s = pickle.loads(auth_dec(rw, c))

    # compute ssid', K, SK
    ssidp = h(sid + ssid + ecp2b(alpha))
    K = key_ex_u(prv_u, x_u, pub_s, X_s, X_u, id_s, id_u, ssidp)
    SK = f(K, b'\x00' + ssidp)

    # compute A_s and verify it equals the one received from the server
    if A_s != f(K, b'\x01' + ssidp):
        abort()

    # compute A_u
    A_u = f(K, b'\x02' + ssidp)

    # sending A_u to server
    send(sock, {'A_u': base64.b64encode(A_u).decode()})

    return SK


try:
    sock = init_socket()

    if args.operation == 'register':
        register_user(sock)

    elif args.operation == 'login':
        SK = login(sock)
        print(SK)

    print('Ok')

except:
    print('Error')

finally:
    print('closing socket')
    sock.close()
