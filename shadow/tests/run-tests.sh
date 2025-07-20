#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    GREEN=""
    RED=""
    YELLOW=""
    BLUE=""
    NC=""
else
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

# Default values
VERBOSE=0
FILTER=""
TEST_TYPE="all"

# Show usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Run tests for the shadow package.

Options:
    -h, --help      Show this help message
    -v, --verbose   Run tests with verbose output
    -f, --filter    Run only tests matching this pattern
    -u, --unit      Run only unit tests
    -i, --integration Run only integration tests

Examples:
    $(basename "$0")                    # Run all tests
    $(basename "$0") -v                 # Run all tests with verbose output
    $(basename "$0") -u                 # Run only unit tests
    $(basename "$0") -f "status"        # Run only tests with "status" in the name

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -f|--filter)
            FILTER="$2"
            shift 2
            ;;
        -u|--unit)
            TEST_TYPE="unit"
            shift
            ;;
        -i|--integration)
            TEST_TYPE="integration"
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}" >&2
            usage
            exit 1
            ;;
    esac
done

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}Error: bats is not installed${NC}" >&2
    echo "Please install bats-core: https://github.com/bats-core/bats-core" >&2
    echo "" >&2
    echo "On macOS: brew install bats-core" >&2
    echo "On Ubuntu/Debian: sudo apt-get install bats" >&2
    echo "Using npm: npm install -g bats" >&2
    exit 1
fi

# Build test file list based on type
TEST_FILES=()
case "$TEST_TYPE" in
    unit)
        TEST_FILES=("${SCRIPT_DIR}"/unit/*.bats)
        echo -e "${BLUE}Running unit tests...${NC}"
        ;;
    integration)
        TEST_FILES=("${SCRIPT_DIR}"/integration/*.bats)
        echo -e "${BLUE}Running integration tests...${NC}"
        ;;
    all)
        TEST_FILES=("${SCRIPT_DIR}"/unit/*.bats "${SCRIPT_DIR}"/integration/*.bats)
        echo -e "${BLUE}Running all tests...${NC}"
        ;;
esac

# Check if we have test files
if [[ ${#TEST_FILES[@]} -eq 0 ]] || [[ ! -f "${TEST_FILES[0]}" ]]; then
    echo -e "${YELLOW}No test files found${NC}"
    exit 0
fi

# Build bats command
BATS_CMD=(bats)

if [[ $VERBOSE -eq 1 ]]; then
    BATS_CMD+=(-v)
fi

if [[ -n "$FILTER" ]]; then
    BATS_CMD+=(-f "$FILTER")
fi

# Run the tests
echo ""
if "${BATS_CMD[@]}" "${TEST_FILES[@]}"; then
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi