--interface:
--  output.short_status
--  output.descriptive_status
--  output.currently_executing

local ansicolors = require "ansicolors"
local s = require 'say'

local output = function()
  local pending_description = function(status, options)
    return "\n\n"..ansicolors("%{yellow}"..s('output.pending')).." → "..
    ansicolors("%{cyan}"..status.info.short_src).." @ "..
    ansicolors("%{cyan}"..status.info.linedefined)..
    "\n"..ansicolors("%{bright}"..status.description)
  end

  local error_description = function(status, options)
    return "\n\n"..ansicolors("%{red}"..s('output.failure')).." → "..
    ansicolors("%{cyan}"..status.info.short_src).." @ "..
    ansicolors("%{cyan}"..status.info.linedefined)..
    "\n"..ansicolors("%{bright}"..status.description)..
    "\n"..status.err..
    ((status.trace and status.trace ~= '') and ("\nTraceback:\n"..status.trace) or "")
  end

  local success_string = function(test_index, test_status)
    return ansicolors(('%%{green} OK  %4d %s'):format(test_index, test_status.description))
  end

  local failure_string = function(test_index, test_status, options)
    return ansicolors(('%%{red}FAIL %4d %s'):format(test_index, test_status.description) .. error_description(test_status, options))
  end

  local pending_string = function(test_index, test_status)
    return ansicolors(('%%{yellow}PEND %d %s'):format(test_index, test_status.description))
  end

  local status_string = function(short_status, descriptive_status, successes, failures, pendings, ms, options)
    local success_str = s('output.success_plural')
    local failure_str = s('output.failure_plural')
    local pending_str = s('output.pending_plural')

    if successes == 0 then
      success_str = s('output.success_zero')
    elseif successes == 1 then
      success_str = s('output.success_single')
    end

    if failures == 0 then
      failure_str = s('output.failure_zero')
    elseif failures == 1 then
      failure_str = s('output.failure_single')
    end

    if pendings == 0 then
      pending_str = s('output.pending_zero')
    elseif pendings == 1 then
      pending_str = s('output.pending_single')
    end

    local formatted_time = ("%.6f"):format(ms):gsub("([0-9])0+$", "%1")

    return short_status.."\n"..
    ansicolors('%{green}'..successes).." "..success_str.." / "..
    ansicolors('%{red}'..failures).." "..failure_str.." / "..
    ansicolors('%{yellow}'..pendings).." "..pending_str.." : "..
    ansicolors('%{bright}'..formatted_time).." "..s('output.seconds').."."..descriptive_status
  end

  local format_statuses = function (statuses, options)
    local short_status = ""
    local descriptive_status = ""
    local successes = 0
    local failures = 0
    local pendings = 0

    for i,status in ipairs(statuses) do
      if status.type == "description" then
        local inner_short_status, inner_descriptive_status, inner_successes, inner_failures, inner_pendings = format_statuses(status, options)
        short_status = short_status..inner_short_status
        descriptive_status = descriptive_status..inner_descriptive_status
        successes = inner_successes + successes
        failures = inner_failures + failures
        pendings = inner_pendings + pendings
      elseif status.type == "success" then
        short_status = short_status..success_string(i, status, options).."\n"
        successes = successes + 1
      elseif status.type == "failure" then
        short_status = short_status..failure_string(i, status, options).."\n"
        descriptive_status = descriptive_status..error_description(status, options)

        if options.verbose then
          descriptive_status = descriptive_status.."\n"..status.trace
        end

        failures = failures + 1
      elseif status.type == "pending" then
        short_status = short_status..pending_string(i, status, options).."\n"
        pendings = pendings + 1

        if not options.suppress_pending then
          descriptive_status = descriptive_status..pending_description(status, options)
        end
      end
    end

    return short_status, descriptive_status, successes, failures, pendings
  end

  local strings = {
    failure = failure_string,
    success = success_string,
    pending = pending_string,
  }

  local index = 1

  return {
    options = {},
    name = "utf_whatever",

    header = function(desc, test_count)
    end,


    formatted_status = function(statuses, options, ms)
      local short_status, descriptive_status, successes, failures, pendings = format_statuses(statuses, options)
      if not options.defer_print then
        short_status = ''
        descriptive_status = ''
      end
      return status_string(short_status, descriptive_status, successes, failures, pendings, ms, options)
    end,

    currently_executing = function(test_status, options)
      print(strings[test_status.type](index, test_status, options))
      index = index + 1
    end
  }
end

return output
