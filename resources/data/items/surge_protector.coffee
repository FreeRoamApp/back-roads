# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'surge-protector'
  id: 'e7664710-ba06-11e8-9337-58da70b4ae7a'
  name: 'Surge Protector'
  categories: ['starting-out']
  why: 'Electricity is not something to mess around with - one bad electrical hookup and you could fry your {home}\'s internal electrical systems. Surge protectors will let you know when a hookup is going to cause problems, and even prevent issues with power surges and outages.'
  what: ''
  decisions: [
    {
      title: '30A vs 50A'
      text: "This one is pretty straight-forward. If your {home} has a 30A (30 Amp) plug, you'll need a 30A surge protector, if it's 50A, you'll need a 50A :)"
    }
    {
      title: 'Self-sacrificing vs Resettable'
      text: "You can spend less to get a surge protector that will sacrifice itself if there\'s a bad surge (meaning you\'ll be protected, but need to buy a new surge protector); or spend more for an expensive surge protector that is able to be reset after power surges"
    }
    {
      title: 'Internal vs External'
      text: "Internal surge protectors are wired into your system from inside the {home}. External surge protectors just plug straight into the pedestal, and you plug your power cord into it. Internal will cost more and be more difficult to install, while external are more easily stolen"
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'LrbBJjWNl2I'}
  ]

products =
  "camco-dogbone-surge-protector-30a":
    name: 'Camco Heavy Duty Dogbone Surge Protector, 30A'
    description: "This is your budget (though they're still a little pricey) surge protector. It informs and protects you from power issues, but doesn't have any extra features beyond that. If it encounters a surge, it will sacrifice itself to save the {home}'s electrical system (which means you'll need a new surge protector)"
    source: 'amazon'
    sourceId: 'B00WED0XBC'
    reviewersLiked: ['Easy to read indicator lights', 'Peace of mind', 'Priced well']
    reviewersDisliked: ['Despite being weather resistant, some had issues with water getting inside', 'Easy to steal', 'Bulky and heavy']
    decisions: ['30A', 'Self-sacrificing', 'External']
    data:
      countryOfOrigin: 'Unknown'

  "southwire-surge-guard-30a":
    name: 'Southwire Surge Guard, 30A'
    description: "This surge protector is a little pricier. It has all of the usual analysis for power problems and will auto-shutoff. This unit is able to reset itself after power issue (it does not \"sacrifice\" itself)"
    source: 'amazon'
    sourceId: 'B07BNVKS9F'
    reviewersLiked: ['Screen with voltage and amperage draw readouts', 'Peace of mind']
    reviewersDisliked: ['Bulky and heavy', 'Easy to steal']
    decisions: ['30A', 'Resettable', 'External']

  "progressive-industries-30a":
    name: 'Progressive Industries 30A EMS'
    description: "This is an internal surge protector that you wire in inside the {home}. It's the most popular brand for this sort of thing and has excellent reviews"
    source: 'amazon'
    sourceId: 'B0050EGS5W'
    reviewersLiked: ['Works flawless', 'Peace of mind', 'Easy to install']
    reviewersDisliked: ['None']
    decisions: ['30A', 'Resettable', 'Internal']


module.exports = {item, products: _.map products, (product, slug) -> _.defaults {itemSlug: item.slug, slug}, product}
# coffeelint: enable=max_line_length,cyclomatic_complexity
