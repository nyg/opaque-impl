#
# https://pymotw.com/3/socket/tcp.html

import argparse
import json
import socket
import sys
import pickle
import base64
from common_opq import *

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

def send(sock, dict):
    sock.sendall(json.dumps(dict).encode())

def ecp2j(ecp, name):
    x, y = ecp.xy()
    return { name + '_x': int(x), name + '_y': int(y) }

def register_user():
    
    sock = init_socket()
    
    # TODO: ask user for pwd
    pw = b'pwd123'
    
    # choose a private and a public key
    prv_u = Integer(Fn.random_element())
    pub_u = prv_u * G
    
    # choose random r
    r = Integer(Fn.random_element())

    # compute alpha
    alpha = hp(pw) + r * G
    
    # tell server we want to register
    #sock.sendall(json.dumps({'op':'register'}).encode())
    
    # send alpha to server
    x, y = alpha.xy()
    send(sock, {'op': 'register', 'alpha_x': int(x), 'alpha_y': int(y)})
    
    # receive beta, v_u and pub_s from server
    data = sock.recv(1024)
    data = json.loads(data)
    
    beta = E(data['beta_x'], data['beta_y'])
    v_u = E(data['v_u_x'], data['v_u_y'])
    pub_s = E(data['P_s_x'], data['P_s_y'])
    
    # compute rw TODO
    rw = h(pw + ecp2b(beta + -r * v_u))
    
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

def login():
    
    sock = init_socket()

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

    
try:
    if args.operation == 'register':
        register_user()
    elif args.operation == 'login':
        login()

finally:
    print('closing socket')
    #sock.close()
