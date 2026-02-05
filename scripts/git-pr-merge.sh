#!/bin/bash
# git-pr-merge.sh - Git PR management utilities
# Usage: git-pr-merge.sh <command> [args]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

get_branch() {
    git branch --show-current
}

get_issue_number() {
    local branch="${1:-$(get_branch)}"
    echo "$branch" | grep -oE '^[0-9]+' || echo ""
}

get_default_branch() {
    gh repo view --json defaultBranchRef -q '.defaultBranchRef.name'
}

get_existing_pr() {
    local branch="${1:-$(get_branch)}"
    gh pr list --head "$branch" --json number,state -q '.[0].number // empty'
}

get_pr_state() {
    local pr_number="$1"
    gh pr view "$pr_number" --json state -q '.state'
}

check_commits_merged() {
    local branch="$1"
    local default_branch="${2:-main}"
    
    if git merge-base --is-ancestor "$branch" "origin/$default_branch" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

cleanup_stale_prs() {
    local default_branch="${1:-main}"
    local closed_count=0
    
    echo -e "${YELLOW}Checking for stale PRs...${NC}"
    
    local open_prs=$(gh pr list --state open --json number,headRefName --jq '.[] | "\(.number):\(.headRefName)"')
    
    for pr_info in $open_prs; do
        local pr_number=$(echo "$pr_info" | cut -d: -f1)
        local branch_name=$(echo "$pr_info" | cut -d: -f2)
        
        if git show-ref --verify --quiet "refs/remotes/origin/$branch_name" 2>/dev/null; then
            if [ "$(check_commits_merged "origin/$branch_name" "$default_branch")" = "true" ]; then
                echo -e "${YELLOW}Closing stale PR #$pr_number (branch: $branch_name)${NC}"
                gh pr close "$pr_number" --comment "Closed: commits already merged into $default_branch"
                git push origin --delete "$branch_name" 2>/dev/null || true
                closed_count=$((closed_count + 1))
            fi
        fi
    done
    
    [ $closed_count -gt 0 ] && echo -e "${GREEN}Closed $closed_count stale PR(s)${NC}" || echo -e "${GREEN}No stale PRs found${NC}"
    echo "$closed_count"
}

close_issue_if_open() {
    local issue_number="$1"
    local pr_number="$2"
    
    [ -z "$issue_number" ] && { echo "no_issue"; return; }
    
    local issue_type=$(gh issue view "$issue_number" --json __typename -q '.__typename' 2>/dev/null || echo "")
    [ "$issue_type" != "Issue" ] && { echo "not_issue"; return; }
    
    local state=$(gh issue view "$issue_number" --json state -q '.state' 2>/dev/null || echo "")
    
    if [ "$state" = "OPEN" ]; then
        gh issue close "$issue_number" --comment "Closed via PR #$pr_number"
        echo "closed"
    else
        echo "already_closed"
    fi
}

do_merge() {
    local pr_number="$1"
    local delete_branch="${2:-true}"
    
    local merge_opts="--squash"
    [ "$delete_branch" = "true" ] && merge_opts="$merge_opts --delete-branch"
    
    gh pr merge "$pr_number" $merge_opts
}

cleanup_local_branch() {
    local branch="$1"
    local default_branch="${2:-main}"
    
    git checkout "$default_branch"
    git pull origin "$default_branch"
    git branch -d "$branch" 2>/dev/null || true
}

case "$1" in
    get-branch)           get_branch ;;
    get-issue-number)     get_issue_number "$2" ;;
    get-default-branch)   get_default_branch ;;
    get-existing-pr)      get_existing_pr "$2" ;;
    get-pr-state)         get_pr_state "$2" ;;
    check-commits-merged) check_commits_merged "$2" "$3" ;;
    cleanup-stale-prs)    cleanup_stale_prs "$2" ;;
    close-issue)          close_issue_if_open "$2" "$3" ;;
    merge)                do_merge "$2" "$3" ;;
    cleanup-local)        cleanup_local_branch "$2" "$3" ;;
    help|--help|-h)
        cat << 'EOF'
Usage: git-pr-merge.sh <command> [args]

Commands:
  get-branch              Get current branch name
  get-issue-number [br]   Extract issue number from branch
  get-default-branch      Get repository default branch
  get-existing-pr [br]    Get PR number for branch
  get-pr-state <pr>       Get PR state (OPEN/MERGED/CLOSED)
  check-commits-merged    Check if branch commits are in main
  cleanup-stale-prs       Find and close stale PRs
  close-issue <num> <pr>  Close issue if open
  merge <pr> [del]        Squash merge PR
  cleanup-local <br>      Cleanup local branch after merge
EOF
        ;;
    *)
        echo "Unknown command: $1. Run 'git-pr-merge.sh help'" >&2
        exit 1
        ;;
esac
