import { check } from 'k6'
import http from 'k6/http'

/// Function to multiply the Virtual Users (VU) based on the amount the experiment will run.
/// Even though multiplying a value by 100 is easy, using this function enables just the extra security of no 'human' mulitplication error occuring.
function calculateTargetVUs(seconds) {
    return 100 * seconds // 100 VU times the seconds we want to run this stress test for.
}

/// The seconds the experiment stress test will run for.
export const seconds = 610

/// The experiment options of how VU are ramped from 0 to the target VU's.
/// The last stage is 10 seconds and it is used for gracefully shutting down all VU's.
export const options = {
    scenarios: {
        test: {
            executor: 'ramping-vus', // ramping-vus executor linearly increases the number of VUs from 0 (startVUs) to the specified target in the first stage.
            startVUs: 0, // The starting number of VUs running when the stress test starts.
            stages: [
                { duration: `${seconds}s`, target: calculateTargetVUs(seconds) },
                { duration: '10s', target: 0 }, // 10 seconds of ramp down, i.e., VUs are shutdown before stress test completes.
            ],
            gracefulRampDown: '0s',
        },
    },
}

/// The main function that each VU runs on k6 experiment.
/// In this method a HTTP get call is performed.
export default function () {
    let url = "http://127.0.0.1:8080/"
    let result = http.get(url)
    check(result, { 'status equals 200': r => r.status == 200 })
}
