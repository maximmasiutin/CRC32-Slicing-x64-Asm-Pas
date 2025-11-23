FROM debian:bookworm-slim

# Install Free Pascal Compiler
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        fpc \
        binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy source files
COPY Crc32Slicing.pas CrcTest.dpr ./

# Create test script
RUN echo '#!/bin/bash' > /app/run_tests.sh && \
    echo 'set -e' >> /app/run_tests.sh && \
    echo 'echo "=== Test 1: Assembler x86-64 (default) ==="' >> /app/run_tests.sh && \
    echo 'fpc -O3 -CX -XX CrcTest.dpr -oCrcTest_asm64' >> /app/run_tests.sh && \
    echo './CrcTest_asm64' >> /app/run_tests.sh && \
    echo '' >> /app/run_tests.sh && \
    echo 'echo "=== Test 2: Pure Pascal ==="' >> /app/run_tests.sh && \
    echo 'fpc -O3 -CX -XX -dPUREPASCAL CrcTest.dpr -oCrcTest_pascal' >> /app/run_tests.sh && \
    echo './CrcTest_pascal' >> /app/run_tests.sh && \
    echo '' >> /app/run_tests.sh && \
    echo 'echo "=== Test 3: Slicing-By-4 ==="' >> /app/run_tests.sh && \
    echo 'fpc -O3 -CX -XX -dSLICING_BY_4 CrcTest.dpr -oCrcTest_slice4' >> /app/run_tests.sh && \
    echo './CrcTest_slice4' >> /app/run_tests.sh && \
    echo '' >> /app/run_tests.sh && \
    echo 'echo "=== All tests passed ==="' >> /app/run_tests.sh && \
    chmod +x /app/run_tests.sh

CMD ["/app/run_tests.sh"]
