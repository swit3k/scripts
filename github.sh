#!/bin/bash

#-------- GitHub 
gh-last-run-id-by-workflow() {
	gh run list --workflow $1 | awk -F'\t' '{ print $7 }' | head -1
}

gh-last-run-id-by-workflow-and-branch() {
	gh run list --workflow $1 --branch $2 | awk -F'\t' '{ print $7 }' | head -1
}

gh-last-build-version() {
	local WORKFLOW_NAME BRANCH BUILD_STATUS RUN_ID
	PARAMS=$(getopt -o w:b: --name "$0" -- "$@")
	eval set -- "$PARAMS"
	while true
	do
		case "$1" in
			-w)
				WORKFLOW_NAME="$2"
				shift 2
				;;
			-b)	BRANCH="$2"
				shift 2
				;;
			--)
				shift
				break
				;;
		esac
	done	

	if [ -z "$WORKFLOW_NAME" ]; then
		WORKFLOW_NAME="build"
	fi

	if [ -z "$BRANCH" ]; then
		BRANCH=$(git branch --show-current)
	fi

	RUN_ID=$(gh-last-run-id-by-workflow-and-branch $WORKFLOW_NAME $BRANCH)
	BUILD_STATUS=$(gh run view $RUN_ID --json conclusion | jq '.conclusion' | xargs)

	if [ "$BUILD_STATUS" = "failure" ]; then
		echo "Last run of '$WORKFLOW_NAME' with ID=$RUN_ID failed. Build version cannot be determined"
		return 1	
	fi
			       
	gh run view $RUN_ID --log | grep image.name | awk -Fazurecr.io/ '{print $2}' | awk -F: '{print $2}' | tail -1 | sed 's/"//'
}

gh-deploy() {
	local WORKFLOW_NAME ENVIRONMENT VERSION BRANCH
	PARAMS=$(getopt -o w:e:v:b: --name "$0" -- "$@")
	eval set -- "$PARAMS"
	while true
	do
		case "$1" in
			-w)
				WORKFLOW_NAME="$2"
				shift 2
				;;
			-e)	ENVIRONMENT="$2"
				shift 2
				;;
			-v)	VERSION="$2"
				shift 2
				;;
			-b)	BRANCH="$2"
				shift 2
				;;
			--)
				shift
				break
				;;
		esac
	done	

	if [ -z "$WORKFLOW_NAME" ]; then
		WORKFLOW_NAME="deploy"
	fi

	if [ -z "$ENVIRONMENT" ]; then
		ENVIRONMENT="QA"
	fi

	if [ -z "$BRANCH" ]; then
		BRANCH=$(git branch --show-current)
	fi

	if [ -z "$VERSION" ]; then
		VERSION=$(gh-last-build-version -b $BRANCH)
		if [ $? -ne 0 ]; then
			echo "$VERSION"
			return 1
		fi
	fi

	gh workflow run $WORKFLOW_NAME --ref $BRANCH -f env="$ENVIRONMENT" -f version="$VERSION"
	#echo "$WORKFLOW_NAME $BRANCH $ENVIRONMENT $VERSION"
}

gh-watch() {
	local WORKFLOW_NAME BRANCH
	PARAMS=$(getopt -o w:b: --name "$0" -- "$@")
	eval set -- "$PARAMS"
	while true
	do
		case "$1" in
			-w)
				WORKFLOW_NAME="$2"
				shift 2
				;;
			-b)	BRANCH="$2"
				shift 2
				;;
			--)
				shift
				break
				;;
		esac
	done	

	if [ -z "$WORKFLOW_NAME" ]; then
		WORKFLOW_NAME="deploy"
	fi
	if [ -z "$BRANCH" ]; then
		BRANCH=$(git branch --show-current)
	fi
	gh run watch $(gh-last-run-id-by-workflow-and-branch $WORKFLOW_NAME $BRANCH)
}
