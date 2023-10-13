#! /usr/bin/env python3
import argparse
import json
import sys

def parse(fin):
    ret = {"status":"unknown"}
    warnings = 0
    has_tv_hdr = 0
    has_result = 0
    check_hrd = 0

    while True:
        line = fin.readline()
        if not line:
            break

        if line.startswith('!!!! WARNING:'):
            warnings += 1
        if line.startswith("T/V "):
            tokens = line.replace("(", " ").replace(")", "").split()
            if tokens[1] != "N":
                continue
            assert tokens == ['T/V', 'N', 'NB', 'P', 'Q', 'Time', 'Gflops', 'per', 'GPU'], f"get tokens: {tokens}"
            has_tv_hdr = 1
        if line.startswith('WC0'):
            t = line.replace("(", " ").replace(")", "").split()
            assert len(t) == 8
            #['WC03R2R2', '264192', '1024', '4', '2', '35.38', '3.474e+05', '4.343e+04']
            wc_header, xhpl_N, xhpl_NB, xhpl_P, xhpl_Q, runtime, tota_gf_str, gpu_gf_str = t
            ret["WC"] = t[0]
            ret["N"] = int(t[1])
            ret["NB"] = int(t[2])
            ret["P"] = int(t[3])
            ret["Q"] = int(t[4])
            ret["time"] = float(t[5])
            ret["total_gflops"] = float(t[6])
            ret["gpu_gflops"] = float(t[7])
            has_result = 1
        if line.startswith('||Ax-b||_oo/(eps'):
            #||Ax-b||_oo/(eps*(||A||_oo*||x||_oo+||b||_oo)*N)=        0.0000013 ...... PASSED
            t=line.split()
            assert len(t) == 4
            ret["status"] = t[3]
            check_hdr = 1

    ret["warnings"] = warnings
    return ret


def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def main():
    exit_code=0

    parser = argparse.ArgumentParser()
    parser.add_argument('log_file')
    parser.add_argument("--json", action='store_true',  default=False)
    parser.add_argument('-w', '--max-warnings', type=int, default=10)
    parser.add_argument('-p', '--min-gflops', type=int, default=0)

    args = parser.parse_args()

    with open(args.log_file, 'r') as fin:
        report = parse(fin)

    if args.json:
        print(json.dumps(report, sort_keys=True, indent=4))

    if report["status"] != "PASSED":
        fail(f'Unexpected status: {report["status"]}')

    if args.max_warnings and args.max_warnings < report["warnings"]:
        fail(f'Too many warnings, got: {report["warnings"]}, max-limit: {args.max_warnings}')

    if args.min_gflops and args.min_gflops > report["gpu_gflops"]:
        fail(f'Performance is too low, got: {report["gpu_gflops"]}, min-limit: {args.min_gflops} GFLOPS')


if __name__ == "__main__":
    main()
