#
# https://pymotw.com/3/socket/tcp.html

import socket
import sys
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

db = {}

def register(data):

    # choose random key for OPRF (different for each user)
    k_u = Integer(Fn.random_element())
    v_u = k_u * G

    # choose private and public key
    prv_s = Integer(Fn.random_element())
    pub_s = prv_s * G

    # compute beta
    alpha = E(data['alpha_x'], data['alpha_y'])
    beta = k_u * alpha

    # send v_u and beta to user
    bx, by = beta.xy()
    vx, vy = v_u.xy()
    px, py = pub_s.xy()
    connection.sendall(json.dumps({
        'beta_x': int(bx),
        'beta_y': int(by),
        'v_u_x': int(vx),
        'v_u_y': int(vy),
        'P_s_x': int(px),
        'P_s_y': int(py)
    }).encode())

    data = recv_json(connection)
    print(data)

    P_u = E(data['P_u_x'], data['P_u_y'])
    c = data['c']

    return {
        'c' : c,
        'p_s': prv_s, 'P_s': pub_s,
        'P_u': P_u,
        'k_u': k_u, 'v_u': v_u
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

    k_s = db[sid]['k_u']
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
