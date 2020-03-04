import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
  duration: '1m',
  vus: 2,
};

export default function() {
  http.get('https://blog.cloudk.id');
  sleep(1);
}