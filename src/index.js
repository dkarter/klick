import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

const ctx = new AudioContext();
const gainNode = ctx.createGain();
gainNode.gain.setValueAtTime(0.2, ctx.currentTime);
gainNode.connect(ctx.destination);

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    currentTime: ctx.currentTime,
  },
});

let timer = null;

app.ports.startAudioClock.subscribe(() => {
  ctx.resume();
  if (timer == null) {
    const readCurrentTime = () => {
      app.ports.audioClockUpdate.send(ctx.currentTime);
      timer = requestAnimationFrame(readCurrentTime);
    };

    timer = requestAnimationFrame(readCurrentTime);
  }
});

app.ports.stopAudioClock.subscribe(() => {
  if (timer) {
    cancelAnimationFrame(timer);
    timer = null;
    ctx.suspend();
  }
});

app.ports.scheduleNote.subscribe(scheduleNote);

function scheduleNote({ time, freqValue, noteDuration }) {
  const osc = ctx.createOscillator();
  osc.frequency.value = freqValue;

  osc.connect(gainNode);
  osc.start(time);
  osc.stop(time + noteDuration);
}

registerServiceWorker();
