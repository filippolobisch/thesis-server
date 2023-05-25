import { check } from 'k6'
import http from 'k6/http'

/// The experiment options of how VU are ramped from 0 to the target VU's.
/// The last stage is 10 seconds and it is used for gracefully shutting down all VU's.
export const options = {
    scenarios: {
        test: {
            executor: 'ramping-vus', // ramping-vus executor linearly increases the number of VUs from 0 (startVUs) to the specified target in the first stage.
            startVUs: 0, // The starting number of VUs running when the stress test starts.
            stages: [
                { duration: '900s', target: 900 } // Reach 100 Virtual Users who perform continuous requests throughout the duration of 610 seconds.
            ],
            gracefulRampDown: '10s',
        },
    },
}

/// The main function that each VU runs on k6 experiment.
/// In this method a HTTP get call is performed.
export default function () {
    http.get("http://0.0.0.0:8080/")
}
