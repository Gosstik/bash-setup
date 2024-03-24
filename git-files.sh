#!/bin/bash

# Misc symbols

GIT_PROMPT_PREFIX="${BOLD_MAGENTA}("
GIT_PROMPT_SUFFIX="${BOLD_MAGENTA})"
GIT_PROMPT_BRANCH="${BOLD_MAGENTA}%s"

# Files symbols

GIT_CONFLICT_PROMPT="${BOLD_RED}×"
GIT_STAGED_PROMPT="${BOLD_GREEN}•"
GIT_CHANGED_PROMPT="${BOLD_YELLOW}+"
GIT_UNTRACKED_PROMPT="${BOLD_CYAN}…"
GIT_STASHED_PROMPT="${BOLD_MAGENTA}⚑ "

# Branch symbols

#GIT_AHEAD_BRANCH="${NORMAL}↑·"
#GIT_BEHIND_BRANCH="${NORMAL}↓·"

GIT_AHEAD_BRANCH="${NORMAL}↑ "
GIT_BEHIND_BRANCH="${NORMAL}↓ "
GIT_UNTRACKED_BRANCH="${NORMAL}_"
GIT_UP_TO_DATE_BRANCH="${NORMAL}↑↓"
GIT_UNKNOWN_BRANCH="${NORMAL}#" # tag or commit with detached HEAD

# GIT_PROMPT_STAGED "$Red● "
# GIT_PROMPT_CONFLICTS "$Red✖ "
# GIT_PROMPT_CHANGED "$Blue✚ "
# GIT_PROMPT_UNTRACKED "…"
# GIT_PROMPT_STASHED "⚑ "

# GIT_PROMPT_SUFFIX ")"
# GIT_PROMPT_SEPARATOR "|"
# GIT_PROMPT_BRANCH "$Magenta"
# GIT_PROMPT_STAGED "$Red● "
# GIT_PROMPT_CONFLICTS "$Red✖ "
# GIT_PROMPT_CHANGED "$Blue✚ "
# GIT_PROMPT_REMOTE " "
# GIT_PROMPT_UNTRACKED "…"
# GIT_PROMPT_STASHED "⚑ "
# GIT_PROMPT_CLEAN "$BGreen✔"

#  local CommandPromptIcon=">_ "
#  # git
#  local BranchIcon=""
#  local StagedIcon="•"
#  local ConflictsIcon="x"
#  local ChangedIcon="+"
#  local RemoteIcon=" "
#  local UntrackedIcon="…"
#  local StashedIcon="⚑${ExtraSpaceAfterIcon}"
#  local CleanIcon="✔"
#  local AheadIcon="↑·"
#  local BehindIcon="↓·"
#  local PrehashIcon=":"
#  local NoRemoteTrackingIcon="L"

function ps1_git_prompt() {
#	REPO_INFO="$(git rev-parse --git-dir \
#	                           --is-inside-git-dir \
#		                         --is-bare-repository \
#		                         --is-inside-work-tree \
#		                         --short HEAD 2>/dev/null)"

  # Check we are in git repo.
	local REPO_INFO REV_PARSE_EXIT_CODE
	REPO_INFO="$(git rev-parse --git-dir 2>/dev/null)"
	REV_PARSE_EXIT_CODE="$?"

	if [ -z "${REPO_INFO}" ]; then
		return "${REV_PARSE_EXIT_CODE}"
	fi

	# Set variables.
	__git_status

	# Create branch status.
	GIT_BRANCH_STATUS=""
	if [ -n "${NUM_AHEAD}" ] && [ -n "${NUM_BEHIND}" ]; then
	  GIT_BRANCH_STATUS="${GIT_AHEAD_BRANCH}${NUM_AHEAD}${GIT_BEHIND_BRANCH}${NUM_BEHIND}"
  elif [ -n "${NUM_BEHIND}" ]; then
    GIT_BRANCH_STATUS="${GIT_BEHIND_BRANCH}${NUM_BEHIND}"
	elif [ -n "${NUM_AHEAD}" ]; then
	  GIT_BRANCH_STATUS="${GIT_AHEAD_BRANCH}${NUM_AHEAD}"
  elif [ "${REMOTE_STATE}" == "_UP_TO_DATE_" ]; then
    GIT_BRANCH_STATUS="${GIT_UP_TO_DATE_BRANCH}"
  elif [ "${REMOTE_STATE}" == "_NO_REMOTE_TRACKING_" ]; then
    GIT_BRANCH_STATUS="${GIT_UNTRACKED_BRANCH}"
  else
    GIT_BRANCH_STATUS="${GIT_UNKNOWN_BRANCH}"
  fi

  if [ -n "${GIT_BRANCH_STATUS}" ]; then
    GIT_BRANCH_STATUS=" ${GIT_BRANCH_STATUS}" # leading whitespace
  fi

  # Create file status.
	GIT_FILES_STATUS=$(ps1_git_files_status)
	if [ -n "${GIT_FILES_STATUS}" ]; then
	  GIT_FILES_STATUS=" ${GIT_FILES_STATUS}"  # leading whitespace
	fi

  PS1_GIT_PROMPT="$(__git_ps1 "${GIT_PROMPT_PREFIX}${GIT_PROMPT_BRANCH}${GIT_BRANCH_STATUS}${GIT_FILES_STATUS}${GIT_PROMPT_SUFFIX}")"
#  PS1_GIT_PROMPT="$(__git_ps1 ' (%s)')"

  echo "${PS1_GIT_PROMPT}"
}

function ps1_git_files_status() {
  #  CURRENT_GIT_STATUS=$("${HOME}/bash-git/git-status.sh")

  GIT_FILES_STATUS=""

  if [ "${NUM_CONFLICTS}" -ne 0 ]; then
    GIT_FILES_STATUS="${GIT_FILES_STATUS}${GIT_CONFLICT_PROMPT}${NUM_CONFLICTS}"
  fi

  if [ "${NUM_STAGED}" -ne 0 ]; then
    GIT_FILES_STATUS="${GIT_FILES_STATUS}${GIT_STAGED_PROMPT}${NUM_STAGED}"
  fi

  if [ "${NUM_CHANGED}" -ne 0 ]; then
    GIT_FILES_STATUS="${GIT_FILES_STATUS}${GIT_CHANGED_PROMPT}${NUM_CHANGED}"
  fi

  if [ "${NUM_TRACKED}" -ne 0 ]; then
    GIT_FILES_STATUS="${GIT_FILES_STATUS}${GIT_UNTRACKED_PROMPT}${NUM_TRACKED}"
  fi

  if [ "${NUM_STASHED}" -ne 0 ]; then
    GIT_FILES_STATUS="${GIT_FILES_STATUS}${GIT_STASHED_PROMPT}${NUM_STASHED}"
  fi

  echo "${GIT_FILES_STATUS}"
}

function __git_status() {
  # -*- coding: utf-8 -*-
  # gitstatus.sh -- produce the current git repo status on STDOUT
  # Functionally equivalent to 'gitstatus.py', but written in bash (not python).
  #
  # Alan K. Stebbens <aks@stebbens.org> [http://github.com/aks]

#  set -u

  if [[ -z "${__GIT_PROMPT_DIR:+x}" ]]; then
    SOURCE="${BASH_SOURCE[0]}"
    while [[ -h "${SOURCE}" ]]; do
      DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
      SOURCE="$(readlink "${SOURCE}")"
      [[ "${SOURCE}" != /* ]] && SOURCE="${DIR}/${SOURCE}"
    done
    __GIT_PROMPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  fi

  if [[ "${__GIT_PROMPT_IGNORE_SUBMODULES:-0}" == "1" ]]; then
    _ignore_submodules="--ignore-submodules"
  else
    _ignore_submodules=""
  fi

  if [[ "${__GIT_PROMPT_WITH_USERNAME_AND_REPO:-0}" == "1" ]]; then
    # returns "user/repo" from remote.origin.url git variable
    #
    # supports urls:
    # https://user@bitbucket.org/user/repo.git
    # https://github.com/user/repo.git
    # git@github.com:user/repo.git
    #
    remote_url=$(git config --get remote.origin.url | sed 's|^.*//||; s/.*@//; s/[^:/]\+[:/]//; s/.git$//')
  else
    remote_url='.'
  fi

  gitstatus=$( LC_ALL=C git --no-optional-locks status ${_ignore_submodules} --untracked-files="${__GIT_PROMPT_SHOW_UNTRACKED_FILES:-normal}" --porcelain --branch )

  # if the status is fatal, exit now
  [[ ! "${?}" ]] && exit 0

  git_dir="$(git rev-parse --git-dir 2>/dev/null)"
  [[ -z "${git_dir:+x}" ]] && exit 0

  __git_prompt_read ()
  {
    local f="${1}"
    shift
    [[ -r "${f}" ]] && read -r "${@}" <"${f}"
  }

  state=""
  step=""
  total=""
  if [[ -d "${git_dir}/rebase-merge" ]]; then
    __git_prompt_read "${git_dir}/rebase-merge/msgnum" step
    __git_prompt_read "${git_dir}/rebase-merge/end" total
    if [[ -f "${git_dir}/rebase-merge/interactive" ]]; then
      state="|REBASE-i"
    else
      state="|REBASE-m"
    fi
  else
    if [[ -d "${git_dir}/rebase-apply" ]]; then
      __git_prompt_read "${git_dir}/rebase-apply/next" step
      __git_prompt_read "${git_dir}/rebase-apply/last" total
      if [[ -f "${git_dir}/rebase-apply/rebasing" ]]; then
        state="|REBASE"
      elif [[ -f "${git_dir}/rebase-apply/applying" ]]; then
        state="|AM"
      else
        state="|AM/REBASE"
      fi
    elif [[ -f "${git_dir}/MERGE_HEAD" ]]; then
      state="|MERGING"
    elif [[ -f "${git_dir}/CHERRY_PICK_HEAD" ]]; then
      state="|CHERRY-PICKING"
    elif [[ -f "${git_dir}/REVERT_HEAD" ]]; then
      state="|REVERTING"
    elif [[ -f "${git_dir}/BISECT_LOG" ]]; then
      state="|BISECTING"
    fi
  fi

  if [[ -n "${step}" ]] && [[ -n "${total}" ]]; then
    state="${state} ${step}/${total}"
  fi

  num_staged=0
  num_changed=0
  num_conflicts=0
  num_untracked=0
  while IFS='' read -r line || [[ -n "${line}" ]]; do
    status="${line:0:2}"
    while [[ -n ${status} ]]; do
      case "${status}" in
        #two fixed character matches, loop finished
        \#\#) branch_line="${line/\.\.\./^}"; break ;;
        \?\?) ((num_untracked++)); break ;;
        U?) ((num_conflicts++)); break;;
        ?U) ((num_conflicts++)); break;;
        DD) ((num_conflicts++)); break;;
        AA) ((num_conflicts++)); break;;
        #two character matches, first loop
        ?M) ((num_changed++)) ;;
        ?\ ) ;;
        #single character matches, second loop
        U) ((num_conflicts++)) ;;
        \ ) ;;
        *) ((num_staged++)) ;;
      esac
      status="${status:0:(${#status}-1)}"
    done
  done <<< "${gitstatus}"

  num_stashed=0
  if [[ "${__GIT_PROMPT_IGNORE_STASH:-0}" != "1" ]]; then
    stash_file="${git_dir}/logs/refs/stash"
    if [[ -e "${stash_file}" ]]; then
      while IFS='' read -r wcline || [[ -n "${wcline}" ]]; do
        ((num_stashed++))
      done < "${stash_file}"
    fi
  fi

  clean=0
  if (( num_changed == 0 && num_staged == 0 && num_untracked == 0 && num_stashed == 0 && num_conflicts == 0)) ; then
    clean=1
  fi

  IFS="^" read -ra branch_fields <<< "${branch_line/\#\# }"
  branch="${branch_fields[@]:0:1}"
  remote=""
  upstream=""

  detached_head=0

  if [[ "${branch}" == *"Initial commit on"* ]]; then
    IFS=" " read -ra fields <<< "${branch}"
    branch="${fields[@]:3:1}"
    remote="_NO_REMOTE_TRACKING_"
    remote_url='.'
  elif [[ "${branch}" == *"No commits yet on"* ]]; then
    IFS=" " read -ra fields <<< "${branch}"
    branch="${fields[@]:4:1}"
    remote="_NO_REMOTE_TRACKING_"
    remote_url='.'
  elif [[ "${branch}" == *"no branch"* ]]; then
    tag=$( git describe --tags --exact-match )
    if [[ -n "${tag}" ]]; then
      branch="_PRETAG_${tag}"
      detached_head=1
    else
      branch="_PREHASH_$( git rev-parse --short HEAD )"
      detached_head=1
    fi
  else
    if [[ "${#branch_fields[@]}" -eq 1 ]]; then
      remote="_NO_REMOTE_TRACKING_"
      remote_url='.'
    else
      IFS="[,]" read -ra remote_fields <<< "${branch_fields[1]}"
      upstream="${remote_fields[@]:0:1}"
      for remote_field in "${remote_fields[@]}"; do
        if [[ "${remote_field}" == "ahead "* ]]; then
          num_ahead="${remote_field:6}"
          ahead="_AHEAD_${num_ahead}"
        fi
        if [[ "${remote_field}" == "behind "* ]]; then
          num_behind="${remote_field:7}"
          behind="_BEHIND_${num_behind# }"
        fi
        if [[ "${remote_field}" == " behind "* ]]; then
          num_behind="${remote_field:8}"
          behind="_BEHIND_${num_behind# }"
        fi
      done
      if [ -z "${num_ahead}" ] && [ -z "${num_behind}" ]; then
        remote="_UP_TO_DATE_"
      fi
#      remote="${behind-}${ahead-}"
    fi
  fi

  if [[ -z "${remote:+x}" ]] ; then
    remote='.'
  fi

  if [[ -z "${upstream:+x}" ]] ; then
    upstream='^'
  fi

  UPSTREAM_TRIMMED=`echo $upstream |xargs`

  #printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
  #  "${branch}${state}" \
  #  "${remote}" \
  #  "${remote_url}" \
  #  "${UPSTREAM_TRIMMED}" \
  #  "${num_staged}" \
  #  "${num_conflicts}" \
  #  "${num_changed}" \
  #  "${num_untracked}" \
  #  "${num_stashed}" \
  #  "${clean}" \
  #  "${detached_head}"

  NUM_STAGED="${num_staged}"
  NUM_CONFLICTS="${num_conflicts}"
  NUM_CHANGED="${num_changed}"
  NUM_TRACKED="${num_untracked}"
  NUM_STASHED="${num_stashed}"
  NUM_AHEAD="${num_ahead}"
  NUM_BEHIND="${num_behind}"
  REMOTE_STATE="${remote}"
}
