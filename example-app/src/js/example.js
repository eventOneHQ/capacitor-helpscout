import { HelpScout } from 'capacitor-helpscout';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    HelpScout.echo({ value: inputValue })
}
