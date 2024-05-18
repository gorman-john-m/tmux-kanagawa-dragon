#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $current_dir/utils.sh

main() {
  # Debug: Notify that the plugin script has started
  tmux display-message "Kanagawa Dragon tmux plugin: Script started"

  # set configuration option variables
  show_kubernetes_context_label=$(get_tmux_option "@kanagawa-dragon-kubernetes-context-label" "")
  eks_hide_arn=$(get_tmux_option "@kanagawa-dragon-kubernetes-eks-hide-arn" false)
  eks_extract_account=$(get_tmux_option "@kanagawa-dragon-kubernetes-eks-extract-account" false)
  hide_kubernetes_user=$(get_tmux_option "@kanagawa-dragon-kubernetes-hide-user" false)
  terraform_label=$(get_tmux_option "@kanagawa-dragon-terraform-label" "")
  show_fahrenheit=$(get_tmux_option "@kanagawa-dragon-show-fahrenheit" true)
  show_location=$(get_tmux_option "@kanagawa-dragon-show-location" true)
  fixed_location=$(get_tmux_option "@kanagawa-dragon-fixed-location")
  show_powerline=$(get_tmux_option "@kanagawa-dragon-show-powerline" false)
  show_flags=$(get_tmux_option "@kanagawa-dragon-show-flags" false)
  show_left_icon=$(get_tmux_option "@kanagawa-dragon-show-left-icon" smiley)
  show_left_icon_padding=$(get_tmux_option "@kanagawa-dragon-left-icon-padding" 1)
  show_military=$(get_tmux_option "@kanagawa-dragon-military-time" false)
  timezone=$(get_tmux_option "@kanagawa-dragon-set-timezone" "")
  show_timezone=$(get_tmux_option "@kanagawa-dragon-show-timezone" true)
  show_left_sep=$(get_tmux_option "@kanagawa-dragon-show-left-sep" )
  show_right_sep=$(get_tmux_option "@kanagawa-dragon-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@kanagawa-dragon-border-contrast" false)
  show_day_month=$(get_tmux_option "@kanagawa-dragon-day-month" false)
  show_refresh=$(get_tmux_option "@kanagawa-dragon-refresh-rate" 5)
  show_synchronize_panes_label=$(get_tmux_option "@kanagawa-dragon-synchronize-panes-label" "Sync")
  time_format=$(get_tmux_option "@kanagawa-dragon-time-format" "")
  show_ssh_session_port=$(get_tmux_option "@kanagawa-dragon-show-ssh-session-port" false)
  IFS=' ' read -r -a plugins <<<$(get_tmux_option "@kanagawa-dragon-plugins" "battery network weather")
  show_empty_plugins=$(get_tmux_option "@kanagawa-dragon-show-empty-plugins" true)

  # Debug: Notify that configuration options have been set
  tmux display-message "Kanagawa Dragon tmux plugin: Configuration options set"

  # Kanagawa Dragon Color Palette
  white='#DCD7BA'        # fujiWhite
  gray='#1F1F28'         # sumiInk4
  dark_gray='#16161D'    # sumiInk2
  light_purple='#6A6A74' # sumiInk5
  dark_purple='#727169'  # sumiInk6
  cyan='#7FB4CA'         # dragonBlue
  green='#98BB6C'        # autumnGreen
  orange='#FF9E3B'       # roninYellow
  red='#E46876'          # autumnRed
  pink='#D27E99'         # sakuraPink
  yellow='#FF9E3B'       # roninYellow

  # Debug: Notify that color palette has been set
  tmux display-message "Kanagawa Dragon tmux plugin: Color palette set"

  # Handle left icon configuration
  case $show_left_icon in
  smiley)
    left_icon="☺"
    ;;
  session)
    left_icon="#S"
    ;;
  window)
    left_icon="#W"
    ;;
  hostname)
    left_icon="#H"
    ;;
  shortname)
    left_icon="#h"
    ;;
  *)
    left_icon=$show_left_icon
    ;;
  esac

  # Debug: Notify that left icon has been configured
  tmux display-message "Kanagawa Dragon tmux plugin: Left icon set to $left_icon"

  # Handle left icon padding
  padding=""
  if [ "$show_left_icon_padding" -gt "0" ]; then
    padding="$(printf '%*s' $show_left_icon_padding)"
  fi
  left_icon="$left_icon$padding"

  # Debug: Notify that left icon padding has been set
  tmux display-message "Kanagawa Dragon tmux plugin: Left icon padding set"

  # Handle powerline option
  if $show_powerline; then
    right_sep="$show_right_sep"
    left_sep="$show_left_sep"
  fi

  # Debug: Notify that powerline option has been handled
  tmux display-message "Kanagawa Dragon tmux plugin: Powerline option set"

  # Set timezone unless hidden by configuration
  if [[ -z "$timezone" ]]; then
    case $show_timezone in
    false)
      timezone=""
      ;;
    true)
      timezone="#(date +%Z)"
      ;;
    esac
  fi

  # Debug: Notify that timezone has been set
  tmux display-message "Kanagawa Dragon tmux plugin: Timezone set to $timezone"

  case $show_flags in
  false)
    flags=""
    current_flags=""
    ;;
  true)
    flags="#{?window_flags,#[fg=${dark_purple}]#{window_flags},}"
    current_flags="#{?window_flags,#[fg=${light_purple}]#{window_flags},}"
    ;;
  esac

  # Debug: Notify that flags have been set
  tmux display-message "Kanagawa Dragon tmux plugin: Flags set"

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval $show_refresh

  # Debug: Notify that refresh interval has been set
  tmux display-message "Kanagawa Dragon tmux plugin: Refresh interval set"

  # set the prefix + t time format
  if $show_military; then
    tmux set-option -g clock-mode-style 24
  else
    tmux set-option -g clock-mode-style 12
  fi

  # Debug: Notify that clock mode style has been set
  tmux display-message "Kanagawa Dragon tmux plugin: Clock mode style set"

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  if $show_border_contrast; then
    tmux set-option -g pane-active-border-style "fg=${light_purple}"
  else
    tmux set-option -g pane-active-border-style "fg=${dark_purple}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # Debug: Notify that pane border styling has been set
  tmux display-message "Kanagawa Dragon tmux plugin: Pane border styling set"

  # message styling
  tmux set-option -g message-style "bg=${gray},fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${gray},fg=${white}"

  # Debug: Notify that message and status bar styling has been set
  tmux display-message "Kanagawa Dragon tmux plugin: Message and status bar styling set"

  # Status left
  if $show_powerline; then
    tmux set-option -g status-left "#[bg=${green},fg=${dark_gray}]#{?client_prefix,#[bg=${yellow}],} ${left_icon} #[fg=${green},bg=${gray}]#{?client_prefix,#[fg=${yellow}],}${left_sep}"
    powerbg=${gray}
  else
    tmux set-option -g status-left "#[bg=${green},fg=${dark_gray}]#{?client_prefix,#[bg=${yellow}],} ${left_icon}"
  fi

  # Debug: Notify that status left has been set
  tmux display-message "Kanagawa Dragon tmux plugin: Status left set"

  # Status right
  tmux set-option -g status-right ""

  for plugin in "${plugins[@]}"; do
    # Debug: Notify which plugin is being configured
    tmux display-message "Kanagawa Dragon tmux plugin: Configuring plugin $plugin"

    if case $plugin in custom:*) true ;; *) false ;; esac then
      script=${plugin#"custom:"}
      if [[ -x "${current_dir}/${script}" ]]; then
        IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-custom-plugin-colors" "cyan dark_gray")
        script="#($current_dir/${script})"
      else
        colors[0]="red"
        colors[1]="dark_gray"
        script="${script} not found!"
      fi

    elif [ $plugin = "cwd" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-cwd-colors" "dark_gray white")
      tmux set-option -g status-right-length 250
      script="#($current_dir/cwd.sh)"

    elif [ $plugin = "fossil" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-fossil-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/fossil.sh)"

    elif [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-git-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/git.sh)"

    elif [ $plugin = "hg" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-hg-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/hg.sh)"

    elif [ $plugin = "battery" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-battery-colors" "pink dark_gray")
      script="#($current_dir/battery.sh)"

    elif [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-gpu-usage-colors" "pink dark_gray")
      script="#($current_dir/gpu_usage.sh)"

    elif [ $plugin = "gpu-ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-gpu-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/gpu_ram_info.sh)"

    elif [ $plugin = "gpu-power-draw" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-gpu-power-draw-colors" "green dark_gray")
      script="#($current_dir/gpu_power.sh)"

    elif [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-cpu-usage-colors" "orange dark_gray")
      script="#($current_dir/cpu_info.sh)"

    elif [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/ram_info.sh)"

    elif [ $plugin = "tmux-ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-tmux-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/tmux_ram_info.sh)"

    elif [ $plugin = "network" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-network-colors" "cyan dark_gray")
      script="#($current_dir/network.sh)"

    elif [ $plugin = "network-bandwidth" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-network-bandwidth-colors" "cyan dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/network_bandwidth.sh)"

    elif [ $plugin = "network-ping" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-network-ping-colors" "cyan dark_gray")
      script="#($current_dir/network_ping.sh)"

    elif [ $plugin = "network-vpn" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-network-vpn-colors" "cyan dark_gray")
      script="#($current_dir/network_vpn.sh)"

    elif [ $plugin = "attached-clients" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-attached-clients-colors" "cyan dark_gray")
      script="#($current_dir/attached_clients.sh)"

    elif [ $plugin = "mpc" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-mpc-colors" "green dark_gray")
      script="#($current_dir/mpc.sh)"

    elif [ $plugin = "spotify-tui" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-spotify-tui-colors" "green dark_gray")
      script="#($current_dir/spotify-tui.sh)"

    elif [ $plugin = "playerctl" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-playerctl-colors" "green dark_gray")
      script="#($current_dir/playerctl.sh)"

    elif [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-kubernetes-context-colors" "cyan dark_gray")
      script="#($current_dir/kubernetes_context.sh $eks_hide_arn $eks_extract_account $hide_kubernetes_user $show_kubernetes_context_label)"

    elif [ $plugin = "terraform" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-terraform-colors" "light_purple dark_gray")
      script="#($current_dir/terraform.sh $terraform_label)"

    elif [ $plugin = "continuum" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-continuum-colors" "cyan dark_gray")
      script="#($current_dir/continuum.sh)"

    elif [ $plugin = "weather" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-weather-colors" "orange dark_gray")
      script="#($current_dir/weather_wrapper.sh $show_fahrenheit $show_location '$fixed_location')"

    elif [ $plugin = "time" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-time-colors" "dark_purple white")
      if [ -n "$time_format" ]; then
        script=${time_format}
      else
        if $show_day_month && $show_military; then # military time and dd/mm
          script="%a %d/%m %R ${timezone} "
        elif $show_military; then # only military time
          script="%a %m/%d %R ${timezone} "
        elif $show_day_month; then # only dd/mm
          script="%a %d/%m %I:%M %p ${timezone} "
        else
          script="%a %m/%d %I:%M %p ${timezone} "
        fi
      fi
    elif [ $plugin = "synchronize-panes" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-synchronize-panes-colors" "cyan dark_gray")
      script="#($current_dir/synchronize_panes.sh $show_synchronize_panes_label)"

    elif [ $plugin = "ssh-session" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-dragon-ssh-session-colors" "green dark_gray")
      script="#($current_dir/ssh_session.sh $show_ssh_session_port)"

    else
      continue
    fi

    if $show_powerline; then
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
      powerbg=${!colors[0]}
    else
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
    fi
  done

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[fg=${gray},bg=${dark_purple}]${left_sep}#[fg=${white},bg=${dark_purple}] #I #W${current_flags} #[fg=${dark_purple},bg=${gray}]${left_sep}"
  else
    tmux set-window-option -g window-status-current-format "#[fg=${white},bg=${dark_purple}] #I #W${current_flags} "
  fi

  tmux set-window-option -g window-status-format "#[fg=${white}]#[bg=${gray}] #I #W${flags}"
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"
}

# run main function
main
