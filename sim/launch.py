#!/usr/bin/env python3
"""Start the offline localhost workbench and open its browser tab."""
import argparse
import socket
import sys
import threading
import time
import webbrowser
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--port',type=int,default=8765)
    p.add_argument('--no-browser',action='store_true')
    args=p.parse_args()
    if not args.no_browser:
        def open_when_ready():
            for _ in range(100):
                try:
                    with socket.create_connection(('127.0.0.1',args.port),timeout=.2): pass
                    webbrowser.open(f'http://127.0.0.1:{args.port}');return
                except OSError: time.sleep(.1)
        threading.Thread(target=open_when_ready,daemon=True).start()
    import uvicorn
    uvicorn.run('turtle_sim.api.app:app',host='127.0.0.1',port=args.port)
