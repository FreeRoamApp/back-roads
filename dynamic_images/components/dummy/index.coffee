_ = require 'lodash'
fs = require 'fs'

Component = require '../'
s = require '../s'
Language = require '../../../models/language'


module.exports = class FortniteStats extends Component
  getHeight: -> 300

  render: ({images, player, language} = {}) ->
    playerName = player.data.info.username
    daysPlayed = player.data.lifetimeStats.timePlayed.match /([0-9]+)d/
    daysPlayed = daysPlayed?[1] or 0
    hoursPlayed = player.data.lifetimeStats.timePlayed.match /([0-9]+)h/
    hoursPlayed = hoursPlayed?[1] or 0
    if daysPlayed
      hoursPlayed = parseInt(daysPlayed) * 24 + parseInt(hoursPlayed)
    # coffeelint: disable=max_line_length,cyclomatic_complexity
    s 'g', {
      'data-name': 'Canvas'
      fill: 'none'
    },
      s 'g', {
        'data-name': 'Frame'
      },
        s 'image', {
          width: '573'
          height: '300'
          'xlink:href': "data:image/png;base64,#{images?.background}"
        }


       s 'g', {
         'data-name': 'Rectangle'
       },
        s 'rect', {
          width: '573'
          height: '300'
          fill: 'black'
          'fill-opacity': '0.4'
        }

       s 'g', {
         'data-name': 'Group 2'
       },
        s 'g', {
          'data-name': 'Frame'
        },
          s 'rect', {
            width: '129'
            height: '250'
            fill: 'white'
            'fill-opacity': '0.2'
            transform: 'translate(12 40)'
          }
          s 'g', {
            'data-name': 'Rectangle 2'
          },
           s 'g', {
             transform: 'translate(12 40)'
           },
            s 'rect', {
              width: '129'
              height: '22'
              fill: 'white'
              'fill-opacity': '0.54'
            }


          s 'g', {
            'data-name': 'Overall'
          },
           s 'g', {
             transform: 'translate(18 46)'
           },
            s 'use', {
              'xlink:href': '#path2'
              fill: 'black'
              'fill-opacity': '0.7'
            }


          s 'g', {
            'data-name': '0.9'
          },
           s 'g', {
             transform: 'translate(18 83)'
           },
            s 'use', {
              'xlink:href': '#path3'
              fill: 'white'
            }


          s 'g', {
            'data-name': 'K/D'
          },
          s 'g', {
            transform: 'translate(18 70)'
          },
           s 'use', {
             'xlink:href': '#path4'
             fill: 'white'
           }


        s 'g', {
        },
          s 'g', {
            transform: 'translate(18 127)'
          },
           s 'use', {
             'xlink:href': '#path5'
             fill: 'white'
           }


        s 'g', {
          'data-name': 'wins'
        },
          s 'g', {
            transform: 'translate(18 114)'
          },
           s 'use', {
             'xlink:href': '#path6'
             fill: 'white'
           }


        s 'g', {
        },
          s 'g', {
            transform: 'translate(18 171)'
          },
           s 'use', {
             'xlink:href': '#path7'
             fill: 'white'
           }


        s 'g', {
          'data-name': 'win %'
        },
          s 'g', {
            transform: 'translate(18 158)'
          },
           s 'use', {
             'xlink:href': '#path8'
             fill: 'white'
           }


        s 'g', {
        },
          s 'g', {
            transform: 'translate(18 259)'
          },
           s 'use', {
             'xlink:href': '#path9'
             fill: 'white'
           }


        s 'g', {
          'data-name': 'kills'
        },
          s 'g', {
            transform: 'translate(18 202)'
          },
           s 'use', {
             'xlink:href': '#path10'
             fill: 'white'
           }


        s 'g', {
        },
          s 'g', {
            transform: 'translate(18 215)'
          },
           s 'use', {
             'xlink:href': '#path11'
             fill: 'white'
           }


        s 'g', {
          'data-name': 'matches'
        },
          s 'g', {
            transform: 'translate(18 246)'
          },
           s 'use', {
             'xlink:href': '#path12'
             fill: 'white'
           }



         s 'g', {
           'data-name': 'Frame'
         },
          s 'rect', {
            width: '129'
            height: '250'
            fill: 'white'
            'fill-opacity': '0.2'
            transform: 'translate(152 40)'
          }
          s 'g', {
            'data-name': 'Rectangle 2'
          },
            s 'g', {
              transform: 'translate(152 40)'
            },
             s 'rect', {
               width: '129'
               height: '22'
               fill: 'white'
               'fill-opacity': '0.54'
             }


          s 'g', {
            'data-name': 'Solo'
          },
            s 'g', {
              transform: 'translate(158 46)'
            },
             s 'use', {
               'xlink:href': '#path14'
               fill: 'black'
               'fill-opacity': '0.7'
             }


          s 'g', {
          },
            s 'g', {
              transform: 'translate(158 83)'
            },
             s 'use', {
               'xlink:href': '#path15'
               fill: 'white'
             }


          s 'g', {
            'data-name': 'K/D'
          },
          s 'g', {
            transform: 'translate(158 70)'
          },
            s 'use', {
              'xlink:href': '#path16'
              fill: 'white'
            }


         s 'g', {
         },
          s 'g', {
            transform: 'translate(158 127)'
          },
            s 'use', {
              'xlink:href': '#path17'
              fill: 'white'
            }


         s 'g', {
           'data-name': 'wins'
         },
          s 'g', {
            transform: 'translate(158 114)'
          },
            s 'use', {
              'xlink:href': '#path18'
              fill: 'white'
            }


         s 'g', {
         },
          s 'g', {
            transform: 'translate(158 171)'
          },
            s 'use', {
              'xlink:href': '#path19'
              fill: 'white'
            }


         s 'g', {
           'data-name': 'win %'
         },
          s 'g', {
            transform: 'translate(158 158)'
          },
            s 'use', {
              'xlink:href': '#path20'
              fill: 'white'
            }


         s 'g', {
         },
          s 'g', {
            transform: 'translate(158 259)'
          },
            s 'use', {
              'xlink:href': '#path21'
              fill: 'white'
            }


         s 'g', {
           'data-name': 'kills'
         },
          s 'g', {
            transform: 'translate(158 202)'
          },
            s 'use', {
              'xlink:href': '#path22'
              fill: 'white'
            }


         s 'g', {
         },
          s 'g', {
            transform: 'translate(158 215)'
          },
            s 'use', {
              'xlink:href': '#path23'
              fill: 'white'
            }


         s 'g', {
           'data-name': ' matches'
         },
          s 'g', {
            transform: 'translate(158 246)'
          },
            s 'use', {
              'xlink:href': '#path24'
              fill: 'white'
            }



        s 'g', {
          'data-name': 'Frame'
        },
         s 'rect', {
           width: '129'
           height: '250'
           fill: 'white'
           'fill-opacity': '0.21'
           transform: 'translate(292 40)'
         }
         s 'g', {
           'data-name': 'Rectangle 2'
         },
          s 'g', {
            transform: 'translate(292 40)'
          },
            s 'rect', {
              width: '129'
              height: '22'
              fill: 'white'
              'fill-opacity': '0.54'
            }


         s 'g', {
           'data-name': 'DUOS'
         },
          s 'g', {
            transform: 'translate(298 46)'
          },
            s 'use', {
              'xlink:href': '#path26'
              fill: 'black'
              'fill-opacity': '0.7'
            }


         s 'g', {
         },
          s 'g', {
            transform: 'translate(298 83)'
          },
            s 'use', {
              'xlink:href': '#path27'
              fill: 'white'
            }


         s 'g', {
           'data-name': 'K/D'
         },
         s 'g', {
           transform: 'translate(298 70)'
         },
          s 'use', {
            'xlink:href': '#path28'
            fill: 'white'
          }


        s 'g', {
        },
         s 'g', {
           transform: 'translate(298 127)'
         },
          s 'use', {
            'xlink:href': '#path29'
            fill: 'white'
          }


        s 'g', {
          'data-name': 'wins'
        },
         s 'g', {
           transform: 'translate(298 114)'
         },
          s 'use', {
            'xlink:href': '#path30'
            fill: 'white'
          }


        s 'g', {
        },
         s 'g', {
           transform: 'translate(298 171)'
         },
          s 'use', {
            'xlink:href': '#path31'
            fill: 'white'
          }


        s 'g', {
          'data-name': 'win %'
        },
         s 'g', {
           transform: 'translate(298 158)'
         },
          s 'use', {
            'xlink:href': '#path32'
            fill: 'white'
          }


        s 'g', {
        },
         s 'g', {
           transform: 'translate(298 259)'
         },
          s 'use', {
            'xlink:href': '#path33'
            fill: 'white'
          }


        s 'g', {
          'data-name': 'kills'
        },
         s 'g', {
           transform: 'translate(298 202)'
         },
          s 'use', {
            'xlink:href': '#path34'
            fill: 'white'
          }


        s 'g', {
        },
         s 'g', {
           transform: 'translate(298 215)'
         },
          s 'use', {
            'xlink:href': '#path35'
            fill: 'white'
          }


        s 'g', {
          'data-name': ' matches'
        },
         s 'g', {
           transform: 'translate(298 246)'
         },
          s 'use', {
            'xlink:href': '#path36'
            fill: 'white'
          }



      s 'g', {
        'data-name': 'Frame'
      },
        s 'rect', {
          width: '129'
          height: '250'
          fill: 'white'
          'fill-opacity': '0.2'
          transform: 'translate(432 40)'
        }
        s 'g', {
          'data-name': 'Rectangle 2'
        },
         s 'g', {
           transform: 'translate(432 40)'
         },
          s 'rect', {
            width: '129'
            height: '22'
            fill: 'white'
            'fill-opacity': '0.54'
          }


        s 'g', {
          'data-name': 'SQUADS'
        },
         s 'g', {
           transform: 'translate(438 46)'
         },
          s 'use', {
            'xlink:href': '#path38'
            fill: 'black'
            'fill-opacity': '0.7'
          }


        s 'g', {
        },
         s 'g', {
           transform: 'translate(438 83)'
         },
          s 'use', {
            'xlink:href': '#path39'
            fill: 'white'
          }


        s 'g', {
          'data-name': 'K/D'
        },
        s 'g', {
          transform: 'translate(438 70)'
        },
         s 'use', {
           'xlink:href': '#path40'
           fill: 'white'
         }


      s 'g', {
      },
        s 'g', {
          transform: 'translate(438 127)'
        },
         s 'use', {
           'xlink:href': '#path41'
           fill: 'white'
         }


      s 'g', {
        'data-name': 'wins'
      },
        s 'g', {
          transform: 'translate(438 114)'
        },
         s 'use', {
           'xlink:href': '#path42'
           fill: 'white'
         }


      s 'g', {
      },
        s 'g', {
          transform: 'translate(438 171)'
        },
         s 'use', {
           'xlink:href': '#path43'
           fill: 'white'
         }


      s 'g', {
        'data-name': 'win %'
      },
        s 'g', {
          transform: 'translate(438 158)'
        },
         s 'use', {
           'xlink:href': '#path44'
           fill: 'white'
         }


      s 'g', {
      },
        s 'g', {
          transform: 'translate(438 259)'
        },
         s 'use', {
           'xlink:href': '#path45'
           fill: 'white'
         }


      s 'g', {
        'data-name': 'kills'
      },
        s 'g', {
          transform: 'translate(438 202)'
        },
         s 'use', {
           'xlink:href': '#path46'
           fill: 'white'
         }


      s 'g', {
      },
        s 'g', {
          transform: 'translate(438 215)'
        },
         s 'use', {
           'xlink:href': '#path47'
           fill: 'white'
         }


      s 'g', {
        'data-name': ' matches'
      },
        s 'g', {
          transform: 'translate(438 246)'
        },
         s 'use', {
           'xlink:href': '#path48'
           fill: 'white'
         }




      s 'g',
        s 'g', {
          transform: 'translate(12 17)'
        },
         s 'use', {
           'xlink:href': '#path49'
           fill: 'white'
         }


      s 'g', {
        'data-name': 'Rectangle 2'
      },
        s 'g', {
          transform: 'translate(489 16)'
        },
          s 'image', {
            width: '16'
            height: '16'
            'xlink:href': "data:image/png;base64,#{images?.platformIcon}"
          }


      s 'g',
        s 'g', {
          transform: 'translate(385 12)'
        },
         s 'use', {
           'xlink:href': '#path51'
           fill: 'white'
         }


      s 'g', {
        'data-name': 'fam_logo_white'
      },
        s 'g', {
          'data-name': 'Group'
        },
         s 'g', {
           'data-name': 'Group'
         },
          s 'g', {
            'data-name': 'Vector'
          },
            s 'g', {
              transform: 'translate(513 16)'
            },
             s 'path', {
               'fill-rule': 'evenodd'
               'clip-rule': 'evenodd'
               d: 'M 4.5 9L 4.5 11.25C 4.5 12.4926 3.49264 13.5 2.25 13.5C 1.00736 13.5 0 12.4926 0 11.25L 0 2.25C 0 1.00736 1.00736 0 2.25 0L 11.25 0C 12.4926 0 13.5 1.00736 13.5 2.25C 13.5 3.49264 12.4926 4.5 11.25 4.5L 9 4.5L 9 6.75C 9 7.99264 7.99264 9 6.75 9L 4.5 9ZM 22.8654 0.991446L 22.8675 0.99L 28.8675 9.99L 28.8654 9.99144C 29.1082 10.3507 29.25 10.7838 29.25 11.25C 29.25 12.4926 28.2426 13.5 27 13.5C 26.2236 13.5 25.539 13.1067 25.1346 12.5086L 25.1325 12.51L 21 6.31125L 16.8675 12.51L 16.8654 12.5086C 16.461 13.1067 15.7764 13.5 15 13.5C 13.7574 13.5 12.75 12.4926 12.75 11.25C 12.75 10.7838 12.8918 10.3507 13.1346 9.99145L 13.1325 9.99L 19.1325 0.99L 19.1346 0.991446C 19.539 0.393256 20.2236 0 21 0C 21.7764 0 22.461 0.393256 22.8654 0.991446ZM 38.3951 8.5465L 38.3925 8.55L 36 6.75562L 36 11.25C 36 12.4926 34.9926 13.5 33.75 13.5C 32.5074 13.5 31.5 12.4926 31.5 11.25L 31.5 2.25C 31.5 1.00736 32.5074 0 33.75 0C 34.2587 0 34.728 0.168822 35.1049 0.453496L 35.1075 0.449999L 39.75 3.93188L 44.3925 0.449999L 44.3951 0.453496C 44.772 0.168822 45.2413 0 45.75 0C 46.9926 0 48 1.00736 48 2.25L 48 11.25C 48 12.4926 46.9926 13.5 45.75 13.5C 44.5074 13.5 43.5 12.4926 43.5 11.25L 43.5 6.75562L 41.1075 8.55L 41.1049 8.5465C 40.728 8.83118 40.2587 9 39.75 9C 39.2413 9 38.772 8.83118 38.3951 8.5465Z'
               fill: 'white'
             }
      s 'defs', {
      },
        s 'text', {
          id: 'path2'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '16'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '11.25'
         },
           Language.get 'fortniteStat.overall', {
             language: language
             file: 'fortnite'
           }

        s 'text', {
          id: 'path3'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '27'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '18.9844'
         }, player.data.lifetimeStats['k/d']

        s 'text', {
          id: 'path4'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '12'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '8.4375'
         },
           Language.get 'fortniteStat.killDeath', {
             language: language
             file: 'fortnite'
           }

        s 'text', {
          id: 'path5'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '27'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '18.9844'
         }, player.data.lifetimeStats.wins or '0'

        s 'text', {
          id: 'path6'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '12'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '8.4375'
         }
           Language.get 'fortniteStat.wins', {
             language: language
             file: 'fortnite'
           }

        s 'text', {
          id: 'path7'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '27'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '18.9844'
         }, player.data.lifetimeStats['win%']

        s 'text', {
          id: 'path8'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '12'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '8.4375'
         },
           Language.get 'fortniteStat.winPercent', {
             language: language
             file: 'fortnite'
           }

        s 'text', {
          id: 'path9'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '27'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '18.9844'
         }, player.data.lifetimeStats.kills or '0'

        s 'text', {
          id: 'path10'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '12'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '8.4375'
         },
           Language.get 'fortniteStat.kills', {
             language: language
             file: 'fortnite'
           }

        s 'text', {
          id: 'path11'
          'xml:space': 'preserve'
          style: 'white-space: pre'
          'font-family': 'Luckiest Guy'
          'font-style': 'Regular'
          'font-size': '27'
          'letter-spacing': '0em'
        },
         s 'tspan', {
           x: '0'
           y: '18.9844'
         }, player.data.lifetimeStats.matches


      s 'text', {
        id: 'path12'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.matches', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path14'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '16'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '11.25'
        },
          Language.get 'fortniteStat.solo', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path15'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.solo['k/d']

      s 'text', {
        id: 'path16'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.killDeath', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path17'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.solo.wins or '0'

      s 'text', {
        id: 'path18'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        }
          Language.get 'fortniteStat.wins', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path19'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.solo['win%']

      s 'text', {
        id: 'path20'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.winPercent', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path21'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.solo.matches

      s 'text', {
        id: 'path22'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.kills', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path23'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.solo.kills or '0'


      s 'text', {
        id: 'path24'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.matches', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path26'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '16'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '11.25'
        },
          Language.get 'fortniteStat.duos', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path27'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.duo['k/d']

      s 'text', {
        id: 'path28'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.killDeath', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path29'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.duo.wins or '0'

      s 'text', {
        id: 'path30'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        }
          Language.get 'fortniteStat.wins', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path31'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.duo['win%']

      s 'text', {
        id: 'path32'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.winPercent', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path33'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.duo.matches

      s 'text', {
        id: 'path34'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.kills', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path35'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.duo.kills or '0'


      s 'text', {
        id: 'path36'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.matches', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path38'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '16'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '11.25'
        },
          Language.get 'fortniteStat.squad', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path39'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.squad['k/d']

      s 'text', {
        id: 'path40'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.killDeath', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path41'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.squad.wins or '0'

      s 'text', {
        id: 'path42'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        }
          Language.get 'fortniteStat.wins', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path43'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.squad['win%']

      s 'text', {
        id: 'path44'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.winPercent', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path45'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.squad.matches

      s 'text', {
        id: 'path46'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.kills', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path47'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '27'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '18.9844'
        }, player.data.group.squad.kills or '0'


      s 'text', {
        id: 'path48'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '8.4375'
        },
          Language.get 'fortniteStat.matches', {
            language: language
            file: 'fortnite'
          }

      s 'text', {
        id: 'path49'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '22'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0'
          y: '15.4688'
        }, playerName

      s 'text', {
        id: 'path51'
        'xml:space': 'preserve'
        style: 'white-space: pre'
        'font-family': 'Luckiest Guy'
        'font-style': 'Regular'
        'font-size': '12'
        'letter-spacing': '0em'
      },
        s 'tspan', {
          x: '0.21875'
          y: '16.4375'
        },
          Language.get 'fortniteStat.hoursPlayed', {
            replacements:
              hours: hoursPlayed
            language: language
            file: 'fortnite'
          }


  # coffeelint: enable=max_line_length,cyclomatic_complexity
