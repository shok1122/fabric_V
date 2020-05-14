require 'date'
require 'open3'

#
# ログ出力
#
def log(_attr, _str, _verbose=true)

    if _verbose then
        d = DateTime.now.strftime("%Y%m%d-%H%M%S")
        _str.lines { |l|
            STDERR.puts "#{d} #{_attr} #{l}"
        }
    else
        STDERR.puts "#{_str}"
    end
end

#
# ログ(INFO)
#
def log_info(_str, _verbose=true)
    log('INFO', _str, _verbose)
end

#
# ログ(ERR)
#
def log_err(_str, _verbose=true)
    log("\e[31mERR\e[0m ", _str, _verbose)
end

#
# ログ(CMD)
#
def log_cmd(_str, _verbose=true)
    log("\e[32mCMD\e[0m ", _str, _verbose)
end

def get_dict(_dct, _key)
    keys = _key.split(':')
    keys.each { |k|
        _dct = _dct[k]
    }
    return _dct
end

#
# コマンド実行
#
def _run(_cmd, _verbose)

    log_cmd(_cmd)

    out = ""
    err = ""
    status = ""

    Open3.popen3(_cmd) do |i, o, e, w|
        o.each  { |line|
            log_info(line, _verbose)
            out += line
        }
        e.each { |line|
            log_err(line, _verbose)
            err += line
        }
        status = w.value # Process::Status object
    end

    return out,err,status
end

def run(_cmd)

    _run(_cmd, true)

end

def run_quiet(_cmd)

    _run(_cmd, false)

end

