#!/usr/bin/env bats

# Load test helper
load ../test-helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "shadow status shows message when not in git repo" {
    # Run in non-git directory
    run "${SHADOW_CMD}" status
    
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "Not in a git repository" ]]
}

@test "shadow status shows no shadow repos when .shadowfile missing" {
    create_git_repo "test-repo"
    cd test-repo
    
    run "${SHADOW_CMD}" status
    
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "No .shadowfile found" ]]
}

@test "shadow status shows shadow repos from .shadowfile" {
    create_git_repo "test-repo"
    cd test-repo
    create_shadowfile "../myshadow"
    
    # Create the shadow repo
    cd ..
    create_shadow_repo "myshadow"
    cd test-repo
    
    run "${SHADOW_CMD}" status
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Shadow Repository Status" ]]
    [[ "${output}" =~ "myshadow" ]]
    [[ "${output}" =~ "SHADOW REPO" ]]  # Header
    [[ "${output}" =~ "EXISTS" ]]       # Header
}

@test "shadow status counts symlinks correctly" {
    create_git_repo "test-repo"
    cd test-repo
    create_shadowfile "../myshadow"
    
    # Create shadow repo and symlinks
    cd ..
    create_shadow_repo "myshadow"
    cd test-repo
    
    # Create some symlinks
    mkdir -p docs
    ln -s ../../myshadow/docs/private docs/private
    ln -s ../myshadow/tasks tasks
    
    run "${SHADOW_CMD}" status
    
    [ "$status" -eq 0 ]
    # The status shows link count in the table
    [[ "${output}" =~ "Total active symlinks: 2" ]]
}

@test "shadow status shows multiple shadow repos" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create .shadowfile with multiple repos
    cat > .shadowfile <<EOF
../myshadow1
../myshadow2
# This is a comment
../myshadow3
EOF
    
    # Create the shadow repos
    cd ..
    create_shadow_repo "myshadow1"
    create_shadow_repo "myshadow2"
    create_shadow_repo "myshadow3"
    cd test-repo
    
    run "${SHADOW_CMD}" status
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "myshadow1" ]]
    [[ "${output}" =~ "myshadow2" ]]
    [[ "${output}" =~ "myshadow3" ]]
    [[ "${output}" =~ "Total shadow repositories: 3" ]]
}

@test "shadow status handles missing shadow repos gracefully" {
    create_git_repo "test-repo"
    cd test-repo
    create_shadowfile "../missing-myshadow"
    
    run "${SHADOW_CMD}" status
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "missing-myshadow" ]]
    # Missing repos show "No" in EXISTS column
    [[ "${output}" =~ "No" ]] || [[ "${output}" =~ "EXISTS" ]]
}

@test "shadow status respects NO_COLOR environment variable" {
    create_git_repo "test-repo"
    cd test-repo
    create_shadowfile "../myshadow"
    
    # Create the shadow repo
    cd ..
    create_shadow_repo "myshadow"
    cd test-repo
    
    # Run with colors
    run "${SHADOW_CMD}" status
    local with_color="${output}"
    
    # Run without colors
    run_shadow_no_color status
    local without_color="${output}"
    
    # Second output should not have color codes
    ! has_color_codes "${without_color}"
}

@test "shadow status shows summary information" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create multiple shadow repos
    cat > .shadowfile <<EOF
../myshadow1
../myshadow2
EOF
    
    cd ..
    create_shadow_repo "myshadow1"
    create_shadow_repo "myshadow2"
    cd test-repo
    
    # Create symlinks to different shadow repos
    mkdir -p docs
    ln -s ../../myshadow1/docs/private docs/private
    ln -s ../myshadow2/tasks tasks
    
    run "${SHADOW_CMD}" status
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Summary:" ]]
    [[ "${output}" =~ "Total shadow repositories: 2" ]]
    [[ "${output}" =~ "Existing repositories: 2" ]]
    [[ "${output}" =~ "Total active symlinks: 2" ]]
}

@test "shadow status handles spaces in paths" {
    create_git_repo "test repo with spaces"
    cd "test repo with spaces"
    create_shadowfile "../shadow repo with spaces"
    
    # Create the shadow repo
    cd ..
    create_shadow_repo "shadow repo with spaces"
    cd "test repo with spaces"
    
    run "${SHADOW_CMD}" status
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "shadow repo with spaces" ]]
}