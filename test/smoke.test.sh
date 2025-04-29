#!/bin/bash

# Initialize FAILED variable
FAILED=0

# Function to print with emojis
log_step() {
    echo -e "\033[1;34m🚀 $1\033[0m"  # Blue for steps
}

log_success() {
    echo -e "\033[1;32m✅ $1\033[0m"  # Green for success
}

log_error() {
    echo -e "\033[1;31m❌ $1\033[0m"  # Red for errors
}

log_info() {
    echo -e "\033[1;33mℹ️ $1\033[0m"  # Yellow for info
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
tcpdump -r ${PCAP} -n

# Check if Snort is correctly configured
echo
log_step "Running Snort..."
stdbuf -oL -eL snort -q \
    -R /test/test.rules \
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
test_types=("ICMP" "HTTP" "UDP")

# Loop through each test type
for test in "${test_types[@]}"; do
    if ! grep -q "$test Test" /tmp/snort-test-output; then
        log_error "Snort $test test failed"
        set_failed
    else
        log_success "Snort $test test passed"
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
