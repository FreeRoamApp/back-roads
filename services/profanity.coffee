log = require 'loga'
_ = require 'lodash'

config = require '../config'

BLACKLIST = [
  'bollock',
  'boner',
  'boob',
  'bitch.*',
  'buttplug',
  'clitoris',
  'cock',
  'crap',
  'cunt.',
  'damn',
  'dick',
  'dicks',
  'dik',
  'dildo',
  'douche',
  'dumbass'
  'dyke',
  'fag',
  'fck',
  'feck',
  'fellate',
  'fellatio',
  'felching',
  '.*f+u+c+k+.*',
  'fuk',
  'fudgepacker',
  'fudge',
  'gay.*',
  '.*hitler.*'
  'packer',
  'flange',
  'homo',
  'horny',
  'jerk',
  'jizz',
  'knobend',
  'labia',
  'nigger.*',
  'nigga.*',
  'nude',
  '.*orgasm.*'
  'penis.*',
  'piss',
  'prick',
  'porn.*',
  'pube',
  'pussy.*',
  'queer',
  'rape',
  'raping',
  'rapist'
  'scrotum',
  'sex.*',
  'shit.*',
  'slut.*',
  'smegma',
  'spunk',
  'tampon',
  'tit',
  'tosser',
  'turd',
  'twat.*',
  '.vagina',
  'wank',
  'whore.*',
  'regalo cuenta'
  'cambio cuenta'
]

LETTER_MAP =
  a: '(a|a\\.|a\\-|4|@|Á|á|À|Â|à|Â|â|Ä|ä|Ã|ã|Å|å|α|Δ|Λ|λ)'
  b: '(b|b\\.|b\\-|8|\\|3|ß|Β|β)'
  c: '(c|c\\.|c\\-|Ç|ç|¢|€|\\<|\\(|\\{|©)'
  d: '(d|d\\.|d\\-|\\|\\)|Þ|þ|Ð|ð)'
  e: '(e|e\\.|e\\-|3|€|È|è|É|é|Ê|ê|∑)'
  f: '(f|f\\.|f\\-|ƒ)'
  g: '(g|g\\.|g\\-|6|9)'
  h: '(h|h\\.|h\\-|Η)'
  i: '(i|i\\.|i\\-|!|\\||\\]\\[|\\]|1|∫|Ì|Í|Î|Ï|ì|í|î|ï)'
  j: '(j|j\\.|j\\-)'
  k: '(k|k\\.|k\\-|Κ|κ)'
  l: '(l|1\\.|l\\-|!|\\||\\]\\[|\\]|£|∫|Ì|Í|Î|Ï)'
  m: '(m|m\\.|m\\-)'
  n: '(n|n\\.|n\\-|η|Ν|Π)'
  o: '(o|o\\.|o\\-|0|Ο|ο|Φ|¤|°|ø)'
  p: '(p|p\\.|p\\-|ρ|Ρ|¶|þ)'
  q: '(q|q\\.|q\\-)'
  r: '(r|r\\.|r\\-|®)'
  s: '(s|s\\.|s\\-|5|\\$|§)'
  t: '(t|t\\.|t\\-|Τ|τ)'
  u: '(u|u\\.|u\\-|υ|µ)'
  v: '(v|v\\.|v\\-|υ|ν)'
  w: '(w|w\\.|w\\-|ω|ψ|Ψ)'
  x: '(x|x\\.|x\\-|Χ|χ)'
  y: '(y|y\\.|y\\-|¥|γ|ÿ|ý|Ÿ|Ý)'
  z: '(z|z\\.|z\\-|Ζ)'


regExpWords = _.map BLACKLIST, (word) ->
  '\\b' + (_.map word, (letter) ->
    LETTER_MAP[letter] or letter
  ).join('') + '\\b'

profaneRegExp = new RegExp "#{regExpWords.join('|')}", 'ig'

class ProfanityService
  isProfane: (str) ->
    hasExcessiveBlockQuotes = str.indexOf('>>>>') isnt -1
    hasExcessiveBlockQuotes or Boolean str?.match profaneRegExp

module.exports = new ProfanityService()
