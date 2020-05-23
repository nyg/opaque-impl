import json
import os
import pickle
import socket
import traceback
import opaque.server as opq_server

from opaque.common import send_json, recv_json, sid

# High-tech database.
db_path = 'db.txt'
db = None

# Create file if it does not exist.
if not os.path.exists(db_path):
    with open(db_path, 'w'): pass


def load_db():
    """
    Load the database into the db variable.
    """
    with open(db_path, 'rb') as file:
        try:
            global db
            db = pickle.load(file)
        except EOFError:
            print('Warning: could not read db, file may be empty…')
            db = {}

def dump_db():
    """
    Serialize the db variable into the database file.
    """
    with open(db_path, 'wb') as file:
        pickle.dump(db, file)


# Start the TCP server
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('localhost', 10001)
print('Starting up on {} port {}'.format(*server_address))
sock.bind(server_address)
sock.listen(1)


while True:

    print('Waiting for a connection…')
    connection, client_address = sock.accept()

    def send(**data):
        return send_json(connection, **data)

    def recv():
        return recv_json(connection)

    try:
        print('Connection from {}… (^C to kill it)'.format(client_address))
        data = recv()

        # Client wants to register.
        if (data['op'] == 'register'):
            load_db()
            db[sid] = opq_server.register(send, recv, data)
            dump_db()

        # Client wants to login.
        elif data['op'] == 'login':
            load_db()
            SK, sid, ssid = opq_server.login(send, recv, db[sid], data)
            if SK is None:
                raise ValueError()
            #else:
            #    print(SK.hex())  # debug only

    except:
        #traceback.print_exc()  # debug only
        print('Error')

    else:
        print('Ok')

    finally:
        print('Closing connection.')
        connection.close()
