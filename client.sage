import argparse
import socket

import opaque.client as opq_client
from opaque.common import send_json, recv_json

# Define available operations
parser = argparse.ArgumentParser()
parser.add_argument('-op', '--operation', required=True, metavar='OP', choices=['register', 'login'], help='...')
args = parser.parse_args()


def init_socket():
    server_address = ('localhost', 10001)
    print('Connecting to {} port {}…'.format(*server_address))
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(server_address)
    return sock


try:
    sock = init_socket()

    def send(**kwargs):
        return send_json(sock, **kwargs)

    def recv():
        return recv_json(sock)

    if args.operation == 'register':
        opq_client.register(send, recv)

    elif args.operation == 'login':
        SK = opq_client.login(send, recv)
        print(SK.hex())

    print('Ok')

except e:
    print(e)
    print('Error')

finally:
    print('Closing socket.')
    sock.close()
