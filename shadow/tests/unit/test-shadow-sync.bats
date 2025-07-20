#!/usr/bin/env bats

# Load test helper
load ../test-helper

# Test the new sync algorithm with relative symlinks

@test "shadow sync creates relative symlinks" {
    # Setup test directory first
    setup_test_dir
    
    # Create main repository
    create_git_repo "main-repo"
    cd main-repo
    
    # Create shadow repository
    cd ..
    create_shadow_repo "myshadow"
    cd myshadow
    
    # Add content to shadow
    mkdir -p docs/tasks
    echo "Private task" > docs/tasks/private.md
    git add .
    git commit -m "Add private content" --quiet
    
    cd ../main-repo
    
    # Add shadow
    run "${SHADOW_CMD}" add ../myshadow
    [ "$status" -eq 0 ]
    
    # Run sync
    run "${SHADOW_CMD}" sync
    [ "$status" -eq 0 ]
    
    # Check that symlink was created with relative path
    [ -L "docs" ]
    
    # Verify the symlink uses a relative path
    link_target=$(readlink "docs")
    [[ "$link_target" == "../"* ]]  # Should start with ../
    [[ "$link_target" == *"myshadow/docs" ]]  # Should end with myshadow/docs
}

@test "shadow sync uses smart traversal - doesn't traverse into symlinked directories" {
    # Setup test directory first
    setup_test_dir
    
    # Create main repository with existing structure
    create_git_repo "main-repo"
    cd main-repo
    mkdir -p docs
    echo "Public doc" > docs/public.md
    git add .
    git commit -m "Initial" --quiet
    
    # Create shadow repository
    cd ..
    create_shadow_repo "myshadow"
    cd myshadow
    
    # Add nested structure
    mkdir -p docs/tasks/subtask1
    mkdir -p docs/tasks/subtask2
    echo "Task 1" > docs/tasks/task1.md
    echo "Subtask 1" > docs/tasks/subtask1/detail.md
    echo "Subtask 2" > docs/tasks/subtask2/info.md
    git add .
    git commit -m "Add tasks" --quiet
    
    cd ../main-repo
    
    # Add shadow
    run "${SHADOW_CMD}" add ../myshadow
    [ "$status" -eq 0 ]
    
    # Run sync
    run "${SHADOW_CMD}" sync
    [ "$status" -eq 0 ]
    
    # Should have created symlink at docs/tasks level, not individual files
    [ -L "docs/tasks" ]
    [ ! -L "docs/tasks/task1.md" ]  # Should NOT exist as separate symlink
    [ ! -L "docs/tasks/subtask1" ]   # Should NOT exist as separate symlink
    
    # Verify content is accessible through the directory symlink
    [ -f "docs/tasks/task1.md" ]
    [ -f "docs/tasks/subtask1/detail.md" ]
    
    # Run sync again - should not report conflicts
    run "${SHADOW_CMD}" sync
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Conflict" ]]
}

@test "shadow sync handles mixed directory structures correctly" {
    # Setup test directory first
    setup_test_dir
    
    # Create main repository with some structure
    create_git_repo "main-repo"
    cd main-repo
    mkdir -p docs/api
    echo "Public API" > docs/api/public.md
    git add .
    git commit -m "Initial" --quiet
    
    # Create shadow repository
    cd ..
    create_shadow_repo "myshadow"
    cd myshadow
    
    # Add content that partially overlaps
    mkdir -p docs/api
    mkdir -p docs/tasks
    mkdir -p tools
    echo "Private API" > docs/api/private.md
    echo "Task" > docs/tasks/todo.md
    echo "Deploy" > tools/deploy.sh
    git add .
    git commit -m "Add shadow content" --quiet
    
    cd ../main-repo
    
    # Add shadow
    run "${SHADOW_CMD}" add ../myshadow
    [ "$status" -eq 0 ]
    
    # Run sync
    run "${SHADOW_CMD}" sync
    [ "$status" -eq 0 ]
    
    # Check symlinks were created at appropriate levels
    [ ! -L "docs" ]  # Should NOT be symlinked (exists as real dir)
    [ -L "docs/tasks" ]  # Should be symlinked (didn't exist)
    [ ! -L "docs/api" ]  # Should NOT be symlinked (exists as real dir)
    [ -L "docs/api/private.md" ]  # Individual file symlink
    [ -L "tools" ]  # Entire directory symlinked
    
    # Verify all content is accessible
    [ -f "docs/api/public.md" ]  # Original file
    [ -f "docs/api/private.md" ]  # Shadow file
    [ -f "docs/tasks/todo.md" ]  # Through directory symlink
    [ -f "tools/deploy.sh" ]  # Through directory symlink
}

@test "shadow sync updates incorrect symlinks to use relative paths" {
    # Setup test directory first
    setup_test_dir
    
    # Create repos
    create_git_repo "main-repo"
    cd main-repo
    
    cd ..
    create_shadow_repo "myshadow"
    cd myshadow
    mkdir -p docs
    echo "Shadow content" > docs/shadow.md
    git add .
    git commit -m "Add content" --quiet
    
    cd ../main-repo
    
    # Create an absolute symlink manually (simulating old behavior)
    ln -s "$(pwd)/../shadow-repo/docs" docs
    
    # Add shadow
    run "${SHADOW_CMD}" add ../myshadow
    [ "$status" -eq 0 ]
    
    # Run sync - should update to relative
    run "${SHADOW_CMD}" sync
    [ "$status" -eq 0 ]
    
    # Check symlink was updated to relative
    link_target=$(readlink "docs")
    [[ "$link_target" == "../"* ]]  # Should be relative now
}