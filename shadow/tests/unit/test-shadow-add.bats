#!/usr/bin/env bats

# Load test helper
load ../test-helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "shadow add fails when not in git repo" {
    # Run in non-git directory
    run "${SHADOW_CMD}" add ../myshadow
    
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "Not in a git repository" ]]
}

@test "shadow add creates .shadowfile when it doesn't exist" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create shadow repo
    cd ..
    create_shadow_repo "myshadow"
    cd test-repo
    
    run "${SHADOW_CMD}" add ../myshadow
    
    [ "$status" -eq 0 ]
    [ -f ".shadowfile" ]
    assert_file_contains ".shadowfile" "../myshadow"
    [[ "${output}" =~ "Added to .shadowfile" ]]
}

@test "shadow add appends to existing .shadowfile" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create initial .shadowfile
    echo "../existing-shadow" > .shadowfile
    
    # Create shadow repos
    cd ..
    create_shadow_repo "existing-shadow"
    create_shadow_repo "new-shadow"
    cd test-repo
    
    run "${SHADOW_CMD}" add ../new-shadow
    
    [ "$status" -eq 0 ]
    assert_file_contains ".shadowfile" "../existing-shadow"
    assert_file_contains ".shadowfile" "../new-shadow"
    
    # Check that there are at least 2 entries
    [ "$(grep -c "^\.\." .shadowfile)" -ge 2 ]
}

@test "shadow add prevents duplicate entries" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create shadow repo
    cd ..
    create_shadow_repo "myshadow"
    cd test-repo
    
    # Add the same repo twice
    run "${SHADOW_CMD}" add ../myshadow
    [ "$status" -eq 0 ]
    
    run "${SHADOW_CMD}" add ../myshadow
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "already in .shadowfile" ]]
    
    # Check that there's only one entry
    [ "$(grep -c "../myshadow" .shadowfile)" -eq 1 ]
}

@test "shadow add updates .git/info/exclude" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create shadow repo
    cd ..
    create_shadow_repo "myshadow"
    cd test-repo
    
    run "${SHADOW_CMD}" add ../myshadow
    
    [ "$status" -eq 0 ]
    
    # Run sync-excludes to update .git/info/exclude
    run "${SHADOW_CMD}" sync-excludes
    [ "$status" -eq 0 ]
    [ -f ".git/info/exclude" ]
    assert_file_contains ".git/info/exclude" ".shadowfile"
}

@test "shadow add handles spaces in shadow repo path" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create shadow repo with spaces
    cd ..
    create_shadow_repo "shadow repo with spaces"
    cd test-repo
    
    run "${SHADOW_CMD}" add "../shadow repo with spaces"
    
    [ "$status" -eq 0 ]
    assert_file_contains ".shadowfile" "../shadow repo with spaces"
}

@test "shadow add preserves comments in .shadowfile" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create .shadowfile with comments
    cat > .shadowfile <<EOF
# Main shadow repository
../shadow-main

# Shared documentation
../shadow-docs
EOF
    
    # Create shadow repos
    cd ..
    create_shadow_repo "shadow-main"
    create_shadow_repo "shadow-docs"
    create_shadow_repo "shadow-new"
    cd test-repo
    
    run "${SHADOW_CMD}" add ../shadow-new
    
    [ "$status" -eq 0 ]
    
    # Check that comments are preserved
    assert_file_contains ".shadowfile" "# Main shadow repository"
    assert_file_contains ".shadowfile" "# Shared documentation"
    assert_file_contains ".shadowfile" "../shadow-new"
}

@test "shadow add normalizes duplicate paths" {
    create_git_repo "test-repo"
    cd test-repo
    
    # Create shadow repo
    cd ..
    create_shadow_repo "myshadow"
    cd test-repo
    
    # Add with different path formats - they should be recognized as the same
    run "${SHADOW_CMD}" add ../myshadow
    [ "$status" -eq 0 ]
    
    run "${SHADOW_CMD}" add ../myshadow/.
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "already in .shadowfile" ]]
    
    # Should only have one entry
    [ "$(grep -c "../myshadow" .shadowfile)" -eq 1 ]
}