# frozen_string_literal: true

class RconAutocomplete
  attr_accessor :query, :reservation

  def initialize(reservation = nil)
    @reservation = reservation
  end

  def autocomplete(query)
    @query = query.downcase

    deep_suggestions = autocomplete_deep_suggestions

    return deep_suggestions if deep_suggestions

    suggestions = autocomplete_exact_start.sort_by { |command| command[:command] }

    return suggestions.first(5) if suggestions

    autocomplete_best_match.first(5).sort_by { |command| command[:command] }
  end

  def autocomplete_deep_suggestions
    send("autocomplete_deep_#{query.split.first}") if self.class.deep_complete_commands.any? { |command| query.split[0] == command[:command] }
  end

  def autocomplete_deep_changelevel
    LeagueMaps.all_league_maps
              .select { |map_name| map_name.downcase.start_with?(query.split[1..].join(' ')) }
              .map { |map_name| { command: "changelevel #{map_name}", description: 'Changes the map' } }
              .sort_by { |command| command[:command] }
  end

  def autocomplete_deep_exec
    self.class.league_configs
        .select { |config| config.downcase.start_with?(query.split[1..].join(' ')) }
        .map { |config| { command: "exec #{config}", description: 'Executes a config' } }
        .sort_by { |command| command[:command] }
  end

  def autocomplete_deep_mp_tournament_whitelist
    self.class.league_whitelists
        .select { |whitelist| whitelist.downcase.start_with?(query.split[1..].join(' ')) }
        .map { |whitelist| { command: "mp_tournament_whitelist #{whitelist}", description: 'Set the tournament whitelist' } }
        .sort_by { |command| command[:command] }
  end

  def autocomplete_deep_tftrue_whitelist_id
    self.class.whitelist_tf_whitelists
        .select { |whitelist| whitelist.downcase.start_with?(query.split[1..].join(' ')) }
        .map { |whitelist| { command: "tftrue_whitelist_id #{whitelist}", description: 'Download and set the latest whitelist from whitelist.tf' } }
        .sort_by { |command| command[:command] }
  end

  def autocomplete_deep_kick
    autocomplete_players
      .map do |ps|
        uid3 = SteamCondenser::Community::SteamId.community_id_to_steam_id3(ps.reservation_player.steam_uid.to_i)
        { command: "kickid \"#{uid3}\"", display_text: "kick \"#{ps.reservation_player.name}\"", description: "Kick #{ps.reservation_player.name}" }
      end
  end

  def autocomplete_deep_kickid
    autocomplete_deep_kick
  end

  def autocomplete_deep_ban
    autocomplete_players
      .map do |ps|
        community_id = ps.reservation_player.steam_uid
        { command: "banid 0 #{community_id} kick", display_text: "ban \"#{ps.reservation_player.name}\"", description: "Ban #{ps.reservation_player.name}" }
      end
  end

  def autocomplete_deep_banid
    autocomplete_deep_ban
  end

  def autocomplete_players
    PlayerStatistic
      .joins(:reservation_player)
      .order('lower(reservation_players.name) ASC')
      .where('reservation_players.reservation_id = ?', reservation.id)
      .where('player_statistics.created_at > ?', 90.seconds.ago)
      .to_a
      .uniq { |ps| ps.reservation_player.steam_uid }
  end

  def autocomplete_exact_start
    self.class.commands_to_suggest
        .select { |command| command[:command].start_with?(query) }
        .sort_by { |command| Text::Levenshtein.distance(command[:command], query) }
  end

  def autocomplete_best_match
    self.class.commands_to_suggest
        .sort_by { |command| Text::Levenshtein.distance(command[:command], query) }
  end

  def self.deep_complete_commands
    [
      { command: 'ban', description: 'Ban a player by name' },
      { command: 'banid', description: 'Ban a player by unique ID' },
      { command: 'changelevel', description: 'Change the map' },
      { command: 'exec', description: 'Execute a config' },
      { command: 'kick', description: 'Kick a player by name' },
      { command: 'kickid', description: 'Kick a player by unique ID' },
      { command: 'mp_tournament_whitelist', description: 'Set the item/weapon whitelist' },
      { command: 'tftrue_whitelist_id', description: 'Set and download the latest whitelist from whitelist.tf' }
    ]
  end

  def self.league_configs
    %w[
      etf2l
      etf2l_6v6
      etf2l_6v6_5cp
      etf2l_6v6_ctf
      etf2l_6v6_koth
      etf2l_6v6_stopwatch
      etf2l_9v9
      etf2l_9v9_5cp
      etf2l_9v9_ctf
      etf2l_9v9_koth
      etf2l_9v9_stopwatch
      etf2l_bball
      etf2l_golden_cap
      etf2l_ultiduo

      rgl_6s_5cp_gc
      rgl_6s_5cp_match
      rgl_6s_5cp_match_half1
      rgl_6s_5cp_match_half2
      rgl_6s_5cp_match_pro
      rgl_6s_5cp_scrim
      rgl_6s_koth_bo5
      rgl_6s_koth
      rgl_6s_koth_match
      rgl_6s_koth_pro
      rgl_6s_koth_scrim
      rgl_7s_koth_bo5
      rgl_7s_koth
      rgl_7s_stopwatch
      rgl_HL_koth_bo5
      rgl_HL_koth
      rgl_HL_stopwatch
      rgl_mm_5cp
      rgl_mm_koth_bo5
      rgl_mm_koth
      rgl_mm_stopwatch
      rgl_off

      ugc_HL_koth
      ugc_HL_standard
      ugc_HL_stopwatch
      ugc_6v_golden
      ugc_6v_koth
      ugc_6v_koth_overtime
      ugc_6v_standard
      ugc_6v_standard_overtime
      ugc_4v_stopwatch
      ugc_4v_golden
      ugc_4v_koth
      ugc_4v_koth_overtime
      ugc_4v_standard
      ugc_4v_standard_overtime
      ugc_4v_stopwatch
      ugc_off
      ugc_UD_ultiduo

      ozfortress_6v6_5cp
      ozfortress_6v6_golden_cap
      ozfortress_6v6_koth
      ozfortress_6v6_scrim
      ozfortress_hl_5cp
      ozfortress_hl_golden_cap
      ozfortress_hl_koth
      ozfortress_hl_stopwatch
      ozfortress_ultiduo
    ]
  end

  def self.league_whitelists
    %w[
      etf2l_whitelist_6v6.txt
      etf2l_whitelist_9v9.txt
      etf2l_whitelist_bball.txt
      etf2l_whitelist_ultiduo.txt

      rgl_6v6_s7.txt
      rgl_7v7_s9.txt
      rgl_9v9_s10.txt
      rgl_nr6s_s3.txt

      item_whitelist_ugc_4v4.txt
      item_whitelist_ugc_6v6.txt
      item_whitelist_ugc_hl.txt
      item_whitelist_ugc_ud.txt
    ]
  end

  def self.whitelist_tf_whitelists
    %w[
      etf2l_whitelist_6v6
      etf2l_whitelist_9v9
      etf2l_whitelist_bball
      etf2l_whitelist_ultiduo

      rgl_6v6
      rgl_7v7
      rgl_9v9
      rgl_nr6s

      item_whitelist_ugc_4v4
      item_whitelist_ugc_6v6
      item_whitelist_ugc_HL
      item_whitelist_ugc_UD
    ]
  end

  def self.commands_to_suggest
    [
      { command: 'ban', description: 'Ban a player' },
      { command: 'banid', description: 'Ban a player by ID' },
      { command: 'banip', description: 'Ban an IP address' },
      { command: 'changelevel', description: 'Change the map' },
      { command: 'exec', description: 'Execute a config' },
      { command: 'host_timescale', description: 'Set the timescale' },
      { command: 'kick', description: 'Kick a player by name' },
      { command: 'kickall', description: 'Kick all players' },
      { command: 'kickid', description: 'Kick a player by ID' },
      { command: 'listid', description: 'List banned STEAM IDs' },
      { command: 'listip', description: 'List banned IPs' },
      { command: 'mp_autoteambalance', description: 'Control autoteambalance' },
      { command: 'mp_disable_respawn_times', description: 'Disable respawn times' },
      { command: 'mp_friendlyfire', description: 'Control friendly fire' },
      { command: 'mp_respawnwavetime', description: 'Set the respawn wave time' },
      { command: 'mp_restartround', description: 'Restart the round' },
      { command: 'mp_scrambleteams', description: 'Scramble teams' },
      { command: 'mp_teams_unbalance_limit', description: 'Set the teams unbalance limit' },
      { command: 'mp_timelimit', description: 'Set the map time limit' },
      { command: 'mp_tournament', description: 'Control tournament mode' },
      { command: 'mp_tournament_restart', description: 'Restart the match' },
      { command: 'mp_tournament_whitelist', description: 'Set the whitelist' },
      { command: 'mp_waitingforplayers_cancel', description: 'Cancel the waiting for players' },
      { command: 'mp_winlimit', description: 'Set the match win limit' },
      { command: 'pause', description: 'Pauses the match' },
      { command: 'removeid', description: 'Remove banned STEAM ID' },
      { command: 'removeip', description: 'Remove banned IP' },
      { command: 'say', description: 'Say something' },
      { command: 'stats', description: 'Show server statistics' },
      { command: 'status', description: 'Show server status' },
      { command: 'sv_alltalk', description: 'Control all talk' },
      { command: 'sv_cheats', description: 'Enable/disable cheats' },
      { command: 'sv_gravity', description: 'Set the gravity' },
      { command: 'sv_pausable', description: 'Control pausability of the match' },
      { command: 'tf_bot_add', description: 'Add a bot' },
      { command: 'tf_bot_difficulty', description: 'Set the bot difficulty' },
      { command: 'tf_bot_kick', description: 'Kick a bot' },
      { command: 'tf_bot_kill', description: 'Kill a bot' },
      { command: 'tf_bot_quota', description: 'Set the bot quota' },
      { command: 'tf_forced_holiday', description: 'Control TF2 holiday mode' },
      { command: 'tf_tournament_classlimit_demoman', description: 'Set the demoman class limit' },
      { command: 'tf_tournament_classlimit_engineer', description: 'Set the engineer class limit' },
      { command: 'tf_tournament_classlimit_heavy', description: 'Set the heavy class limit' },
      { command: 'tf_tournament_classlimit_medic', description: 'Set the medic class limit' },
      { command: 'tf_tournament_classlimit_pyro', description: 'Set the pyro class limit' },
      { command: 'tf_tournament_classlimit_scout', description: 'Set the scout class limit' },
      { command: 'tf_tournament_classlimit_sniper', description: 'Set the sniper class limit' },
      { command: 'tf_tournament_classlimit_soldier', description: 'Set the soldier class limit' },
      { command: 'tf_tournament_classlimit_spy', description: 'Set the spy class limit' },
      { command: 'tf_use_fixed_weaponspreads', description: 'Control random weapon spread' },
      { command: 'tf_weapon_criticals', description: 'Toggle critical hits' },
      { command: 'tf_avoidteammates_pushaway', description: 'Whether or not teammates push each other away when occupying the same space' },
      { command: 'tftrue_whitelist_id', description: 'Set the whitelist with TFTrue' },
      { command: 'tv_delay', description: 'Set the STV delay' },
      { command: 'tv_delaymapchange', description: 'Control map change delay to allow STV to finish broadcasting' },
      { command: 'tv_delaymapchange_protect', description: 'Protect against doing a manual map change if HLTV is broadcasting and has not caught up with a major game event such as round_end' },
      { command: 'tv_record', description: 'Start STV recording' },
      { command: 'tv_stoprecord', description: 'Stop STV recording' }
    ]
  end
end
