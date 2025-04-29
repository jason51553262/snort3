#!/bin/bash

# Initialize FAILED variable
FAILED=0

log_lines() {
    local color="$1"
    local emoji="$2"
    local message="$3"
    while IFS= read -r line; do
        echo -e "${color}${emoji} ${line}\033[0m"
    done <<< "$message"
}

log_step() {
    log_lines "\033[1;34m" "🚀" "$1"  # Blue
}

log_success() {
    log_lines "\033[1;32m" "✅" "$1"  # Green
}

log_error() {
    log_lines "\033[1;31m" "❌" "$1"  # Red
}

log_info() {
    log_lines "\033[1;33m" "ℹ️" "$1"  # Yellow
}


set_failed() {
    FAILED=1
}

# Test setup message
echo
log_info "Starting Snort test..."

PCAP=/test/test.pcap

# Display rule file contents
echo
log_step "Test Rules Content..."
cat /test/test.rules

# Display the pcap contents first
echo
log_step "Pcap Content..."
tcpdump -nn -vvv -X -r ${PCAP}

# Check if Snort is correctly configured
echo
log_step "Running Snort..."
stdbuf -oL -eL snort -q \
    -R /test/test.rules \
    -k none \
    -c /etc/snort/snort.lua \
    -r ${PCAP} > /tmp/snort-test-output 2>&1

# Print output
echo
log_step "Test Output..."
cat /tmp/snort-test-output

# Run checks for ICMP, HTTP, UDP in output
echo
log_step "Verifying test results..."

# Define an array of test types
test_types=("ICMP" "HTTP" "TCP" "UDP")

# Loop through each test type
for test in "${test_types[@]}"; do
    if ! grep -q "$test Test" /tmp/snort-test-output; then
        log_error "Snort $test test failed"
        set_failed
    else
        log_success "Snort $test test passed"
        log_info "$(grep "$test Test" /tmp/snort-test-output)"
    fi
done

# Exit if any test failed
if [ $FAILED -eq 1 ]; then
    echo
    log_error "One or more tests failed. Exiting..."
    exit 1
fi

echo
log_success "All tests passed successfully! 🎉"
