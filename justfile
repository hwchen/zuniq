build-release:
    zig build --zig-lib-dir ~/zigdev/zig/lib install -Drelease-fast

install prefix-path:
    zig build --zig-lib-dir ~/zigdev/zig/lib -Drelease-fast && cp zig-out/bin/zuniq {{prefix-path}}/.

bench input-file: build-release
    hyperfine --warmup 10 'zig-out/bin/zuniq {{input-file}}' 'runiq {{input-file}}'

perf input-file: build-release
    perf record --call-graph dwarf zig-out/bin/zuniq {{input-file}}

perf-report:
    perf report

flamegraph:
    perf script | stackcollapse-perf.pl | flamegraph.pl > perf.svg && \
    firefox perf.svg

