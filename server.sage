import socket
import json
import base64

from common import *

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Bind the socket to the port
server_address = ('localhost', 10001)
print('starting up on {} port {}'.format(*server_address))
sock.bind(server_address)

# Listen for incoming connections
sock.listen(1)

# High-tech database, do not turn off the server!!1
db = {}

def register(data):

    # choose random key for OPRF (different for each user)
    k_s = Integer(Fn.random_element())

    # choose private and public key
    p_s = Integer(Fn.random_element())
    P_s = p_s * G

    # compute beta
    alpha = j2ecp(data, E, 'alpha')
    beta = k_s * alpha

    # send v_u and beta to user
    data = ecp2j(beta, 'beta')
    data.update(ecp2j(P_s, 'P_s'))
    send(connection, data)

    # receive c and P_u from user
    data = recv_json(connection)
    P_u = E(data['P_u_x'], data['P_u_y'])
    c = data['c']

    return {
        'k_s': k_s,
        'p_s': p_s, 'P_s': P_s,
        'P_u': P_u,
        'c' : c
    }

def login(data):

    alpha = j2ecp(data, E, 'alpha')

    # check alpha belongs to the curve
    x, y = alpha.xy()
    if not E.is_on_curve(x, y):
        abort()

    X_u = j2ecp(data, E, 'X_u')

    # choose x_s
    x_s = Integer(Fn.random_element())

    k_s = db[sid]['k_s']
    p_s = db[sid]['p_s']
    P_s = db[sid]['P_s']
    P_u = db[sid]['P_u']
    c = db[sid]['c']

    # compute beta and and X_s
    beta = alpha * k_s
    X_s = x_s * G

    # compute ssid', K, SK and A_s
    ssidp = h(sid + ssid + ecp2b(alpha))
    K = key_ex_s(p_s, x_s, P_u, X_u, X_s, id_s, id_u, ssidp)
    SK = f(K, b'\x00' + ssidp)
    A_s = f(K, b'\x01' + ssidp)

    # send beta, X_s, c and A_s
    data = ecp2j(beta, 'beta')
    data.update(ecp2j(X_s, 'X_s'))
    data.update({
        'c': c,
        'A_s': base64.b64encode(A_s).decode()
    })
    send(connection, data)

    data = recv_json(connection)
    A_u = base64.b64decode(data['A_u'].encode())

    # compute A_u and verify it equals the one received from the user
    if A_u != f(K, b'\x02' + ssidp):
        abort()

    return SK

while True:

    print('waiting for a connection')
    connection, client_address = sock.accept()

    try:
        print('connection from', client_address)

        data = connection.recv(1024)
        if not data:
            continue

        data = json.loads(data)
        print('received {!r}'.format(data))

        if (data['op'] == 'register'):
            db[sid] = register(data)

        elif data['op'] == 'login':
            SK = login(data)
            print(SK)

    finally:
        connection.close()
