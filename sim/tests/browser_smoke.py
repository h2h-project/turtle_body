"""Offline browser integration using temporary personal data and an owned server."""
from pathlib import Path
import os
import json
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[2]


def main():
    with tempfile.TemporaryDirectory(prefix='turtle-browser-') as td:
        with socket.socket() as s:s.bind(('127.0.0.1',0));port=s.getsockname()[1]
        url=f'http://127.0.0.1:{port}'
        env={**os.environ,'TURTLE_SIM_DATA':td}
        with open(Path(td)/'server.log','w+') as log:
            server=subprocess.Popen([sys.executable,str(ROOT/'sim/launch.py'),'--no-browser','--port',str(port)],cwd=ROOT,env=env,stdout=log,stderr=log)
            try:
                for _ in range(100):
                    try:
                        urllib.request.urlopen(url+'/api/config',timeout=.5);break
                    except OSError:time.sleep(.1)
                else:
                    log.seek(0);raise RuntimeError(log.read())
                with sync_playwright() as p:
                    browser=p.chromium.launch(executable_path=os.environ.get('CHROME_BIN','/usr/bin/google-chrome'),headless=True,args=['--no-sandbox','--disable-dev-shm-usage','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
                    page=browser.new_page(viewport={'width':1450,'height':1050},accept_downloads=True)
                    errors=[];external=[]
                    page.on('pageerror',lambda e:errors.append(str(e)))
                    def route(r):
                        if r.request.url.startswith(url):r.continue_()
                        else:external.append(r.request.url);r.abort()
                    page.route('**/*',route)
                    geometry=json.load(urllib.request.urlopen(url+'/api/geometry'))
                    assert geometry['ready'],'Run .venv/bin/python build/export_sim.py before this geometry/browser integration test'
                    page.goto(url)
                    page.wait_for_selector('#components details',timeout=60000)
                    assert page.locator('#components details').count()==13
                    assert page.locator('#solve').is_disabled()
                    assert page.locator('#front').inner_text()=='—'
                    page.locator('#name').fill('Browser trial A')
                    page.locator('#name').blur()
                    page.locator('#density_source').select_option('seawater_reference')
                    assert page.locator('#density').input_value()=='1025'
                    page.locator('#components summary').first.click()
                    page.locator('#components input[type=number]').first.fill('0.5')
                    page.locator('#components input[type=number]').first.blur()
                    page.locator('#save').click()
                    page.wait_for_function("document.querySelector('#status').textContent.includes('saved locally')")
                    with page.expect_download() as d:page.locator('#download').click()
                    download=Path(td)/'download.yaml';d.value.save_as(download)
                    assert 'Browser trial A' in download.read_text()
                    page.reload();page.wait_for_selector('#components details')
                    assert page.locator('#name').input_value()=='Browser trial A'
                    assert page.locator('#density').input_value()=='1025'
                    page.locator('#addpayload').click()
                    page.locator('#addtrial').click()
                    page.locator('#save').click()
                    page.wait_for_function("document.querySelector('#status').textContent.includes('saved locally')")
                    page.locator('#load').set_input_files(download)
                    page.wait_for_function("document.querySelector('#status').textContent.includes('Configuration loaded')")
                    assert page.locator('#payloads .payload').count()==0
                    assert page.locator('#trials .trial').count()==0
                    page.screenshot(path='/tmp/turtle-workbench.png',full_page=True)
                    # Exercise the REAL process worker with explicitly synthetic data.
                    synthetic=json.loads(json.dumps(page.request.get(url+'/api/config').json()))
                    synthetic.update(name='Browser synthetic box',density_kg_m3=1000,density_source='measured',dimensions_checked=True,
                        observations=[],payloads=[{'id':'test-box','mass_kg':4,'com_m':[0,0,0],
                            'displacement':'box','size_m':[.4,.3,.1],'notes':'Synthetic test fixture only'}])
                    for c in synthetic['components']:c['installed']=False
                    fixture=Path(td)/'synthetic.json';fixture.write_text(json.dumps(synthetic))
                    page.locator('#load').set_input_files(fixture)
                    page.wait_for_function("!document.querySelector('#solve').disabled")
                    page.locator('#solve').click()
                    page.wait_for_function("document.querySelector('#status').textContent.includes('Calculation complete')",timeout=60000)
                    assert page.locator('#graphs figure').count()==2
                    assert '4.000 kg' in page.locator('#results').inner_text()
                    assert page.locator('#front').inner_text()=='absent'
                    # A later edit while a solve is running must discard its old result.
                    page.locator('#solve').click()
                    page.locator('#name').fill('Edited while solving');page.locator('#name').blur()
                    page.wait_for_function("document.querySelector('#status').textContent.includes('Old result discarded')",timeout=60000)
                    assert page.locator('#graphs figure').count()==0
                    # Mobile layout should neither overflow nor lose the action controls.
                    page.set_viewport_size({'width':430,'height':850})
                    assert page.evaluate('document.documentElement.scrollWidth<=window.innerWidth')
                    assert not errors,errors
                    assert not external,external
                    browser.close()
                print('PASS: offline browser, measurement gating, edit/save/reload, YAML download/import, partial trials/loads, real worker solve, stale-result rejection, responsive layout; no browser errors')
            finally:
                server.terminate()
                try:server.wait(timeout=10)
                except subprocess.TimeoutExpired:server.kill();server.wait()

if __name__=='__main__':main()
