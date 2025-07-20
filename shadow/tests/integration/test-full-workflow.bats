#!/usr/bin/env bats

# Load test helper
load ../test-helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "full workflow: add, extract, sync, import" {
    # Create main repository
    create_git_repo "my-project"
    cd my-project
    
    # Create some content
    mkdir -p docs/public
    echo "Public documentation" > docs/public/api.md
    create_file "docs/internal/secrets.md" "Internal secrets"
    create_file "tasks/todo.md" "Private tasks"
    git add .
    git commit -m "Add content" --quiet
    
    # Create shadow repository
    cd ..
    create_shadow_repo "my-project-shadow"
    cd my-project
    
    # Add shadow repository
    run "${SHADOW_CMD}" add ../my-project-shadow
    [ "$status" -eq 0 ]
    
    # Extract private content to shadow
    run "${SHADOW_CMD}" extract docs/internal ../my-project-shadow
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Successfully extracted to shadow" ]]
    
    # Check that original is now a symlink
    [ -L "docs/internal" ]
    
    # Extract another file
    run "${SHADOW_CMD}" extract tasks/todo.md ../my-project-shadow
    [ "$status" -eq 0 ]
    
    # Check shadow status
    run "${SHADOW_CMD}" status
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Total active symlinks: 2" ]]
    
    # Verify content is accessible through symlinks
    [ "$(cat docs/internal/secrets.md)" = "Internal secrets" ]
    [ "$(cat tasks/todo.md)" = "Private tasks" ]
    
    # Test sync-excludes
    run "${SHADOW_CMD}" sync-excludes
    [ "$status" -eq 0 ]
    assert_file_contains ".git/info/exclude" "docs/internal"
    assert_file_contains ".git/info/exclude" "tasks/todo.md"
    
    # Remove symlinks to test sync
    rm -f docs/internal tasks/todo.md
    
    # Run sync to recreate symlinks
    run "${SHADOW_CMD}" sync
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Creating symlink" ]] || [[ "${output}" =~ "created" ]]
    
    # Verify symlinks were recreated
    [ -L "docs/internal" ]
    [ -L "tasks/todo.md" ]
    
    # Test import back to main repo
    run "${SHADOW_CMD}" import --force docs/internal
    [ "$status" -eq 0 ]
    
    # Verify it's no longer a symlink
    [ ! -L "docs/internal" ]
    [ -d "docs/internal" ]
    [ -f "docs/internal/secrets.md" ]
}

@test "multiple shadow repositories workflow" {
    # Create main repository
    create_git_repo "multi-shadow-project"
    cd multi-shadow-project
    
    # Create content for different shadow repos
    create_file "docs/private/design.md" "Private design docs"
    create_file "tasks/personal.md" "Personal tasks"
    create_file "marketing/strategy.md" "Marketing strategy"
    git add .
    git commit -m "Initial content" --quiet
    
    # Create multiple shadow repositories
    cd ..
    create_shadow_repo "project-docs-shadow"
    create_shadow_repo "project-tasks-shadow"
    create_shadow_repo "project-marketing-shadow"
    cd multi-shadow-project
    
    # Add all shadow repositories
    run "${SHADOW_CMD}" add ../project-docs-shadow
    [ "$status" -eq 0 ]
    
    run "${SHADOW_CMD}" add ../project-tasks-shadow
    [ "$status" -eq 0 ]
    
    run "${SHADOW_CMD}" add ../project-marketing-shadow
    [ "$status" -eq 0 ]
    
    # Extract to different shadow repos
    run "${SHADOW_CMD}" extract docs/private ../project-docs-shadow
    [ "$status" -eq 0 ]
    
    run "${SHADOW_CMD}" extract tasks ../project-tasks-shadow
    [ "$status" -eq 0 ]
    
    run "${SHADOW_CMD}" extract marketing ../project-marketing-shadow
    [ "$status" -eq 0 ]
    
    # Check status shows all shadow repos
    run "${SHADOW_CMD}" status
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "project-docs-shadow" ]]
    [[ "${output}" =~ "project-tasks-shadow" ]]
    [[ "${output}" =~ "project-marketing-shadow" ]]
    [[ "${output}" =~ "Total active symlinks: 3" ]]
    
    # Skip sync-repos test as it requires interactive input
    # TODO: Add --force flag to sync-repos for non-interactive testing
    
    # Instead, verify that changes in shadow repos are visible through symlinks
    cd ../project-docs-shadow
    echo "Updated design" >> docs/private/design.md
    cd ../multi-shadow-project
    
    # Verify the change is visible through the symlink without sync-repos
    [[ "$(cat docs/private/design.md)" =~ "Updated design" ]]
}

@test "error recovery: broken symlinks" {
    # Create main repository
    create_git_repo "broken-project"
    cd broken-project
    
    # Create shadow and add it
    cd ..
    create_shadow_repo "broken-shadow"
    cd broken-project
    
    run "${SHADOW_CMD}" add ../broken-shadow
    [ "$status" -eq 0 ]
    
    # Create content and extract
    create_file "important/data.txt" "Important data"
    git add .
    git commit -m "Add data" --quiet
    
    run "${SHADOW_CMD}" extract important ../broken-shadow
    [ "$status" -eq 0 ]
    
    # Break the shadow by removing the target
    rm -rf ../broken-shadow/important
    
    # Status should still work with broken symlinks
    run "${SHADOW_CMD}" status
    [ "$status" -eq 0 ]
    
    # Sync should handle broken symlinks gracefully
    run "${SHADOW_CMD}" sync
    # Should complete (possibly with warnings)
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    
    # Fix by recreating shadow content
    mkdir -p ../broken-shadow/important
    echo "Recovered data" > ../broken-shadow/important/data.txt
    
    # Now sync should work properly
    run "${SHADOW_CMD}" sync
    [ "$status" -eq 0 ]
}

@test "git exclude automation" {
    # Create main repository
    create_git_repo "exclude-test"
    cd exclude-test
    
    # Add shadow
    cd ..
    create_shadow_repo "exclude-shadow"
    cd exclude-test
    
    run "${SHADOW_CMD}" add ../exclude-shadow
    [ "$status" -eq 0 ]
    
    # Create and extract multiple paths
    create_file "secret1.txt" "Secret 1"
    create_file "dir/secret2.txt" "Secret 2"
    create_file "deep/nested/secret3.txt" "Secret 3"
    git add .
    git commit -m "Add secrets" --quiet
    
    # Extract all
    run "${SHADOW_CMD}" extract secret1.txt ../exclude-shadow
    [ "$status" -eq 0 ]
    
    run "${SHADOW_CMD}" extract dir/secret2.txt ../exclude-shadow
    [ "$status" -eq 0 ]
    
    run "${SHADOW_CMD}" extract deep ../exclude-shadow
    [ "$status" -eq 0 ]
    
    # Check that sync-excludes adds all paths
    run "${SHADOW_CMD}" sync-excludes
    [ "$status" -eq 0 ]
    
    # Verify all paths are in exclude file
    assert_file_contains ".git/info/exclude" "secret1.txt"
    assert_file_contains ".git/info/exclude" "dir/secret2.txt"
    assert_file_contains ".git/info/exclude" "deep"
    assert_file_contains ".git/info/exclude" ".shadowfile"
    
    # Run sync-excludes again - should be idempotent
    run "${SHADOW_CMD}" sync-excludes
    [ "$status" -eq 0 ]
    
    # Count occurrences - should not duplicate
    [ "$(grep -c "secret1.txt" .git/info/exclude)" -eq 1 ]
}