build-release:
    zig build install -Drelease-fast -p zig-out

build-release-patched:
    zig build install -Drelease-fast -p zig-out/patched --zig-lib-dir ~/zigdev/zig/lib

install-patched prefix-path: build-release-patched
    cp zig-out/patched/bin/zuniq {{prefix-path}}/.

bench input-file: build-release build-release-patched
    hyperfine --warmup 10 'zig-out/bin/zuniq {{input-file}}' 'zig-out/patched/bin/zuniq {{input-file}}' 'runiq {{input-file}}'

perf input-file: build-release
    perf record --call-graph dwarf zig-out/bin/zuniq {{input-file}}

perf-report:
    perf report

flamegraph:
    perf script | stackcollapse-perf.pl | flamegraph.pl > perf.svg && \
    firefox perf.svg

