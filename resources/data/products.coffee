# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO:
# parameters: [{name: 'name', value: 'value'}]
# eg: parameters: [{name: 'watts', value: 100}, {name: 'type', value: 'monocrystalline'}]
# eg2: parameters: [{name: 'type', value: 'roof-caulk'}]
# eg3: water pressure regulator parameters: [{name: 'hasGauge', value: true}] / [{name: 'hasGauge', value: false}]

products =
  "camco-heavy-duty-dogbone-rv-surge-protector":
    name: 'Camco Heavy Duty Dogbone Surge Protector, 30A'
    description: "The Camco 30M/30F AMP Circuit Analyzer helps protect your electrical equipment from improperly wired electrical boxes by visually indicating faults before you connect your RV's Power Cord to the electrical box. The 125V Dogbone includes surge protection up to 2100 joules. It is weatherproof, with durable power grip handles for safe and easy plugging and unplugging. NEMA TT-30 Plug and Receptacle."
    itemSlug: 'surge-protector'
    source: 'amazon'
    sourceId: 'B00WED0XBC'
    reviewersLiked: ['Easy to read indicator lights', 'Peace of mind', 'Priced well']
    reviewersDisliked: ['Despite being weather resistant, some had issues with water getting inside', 'Easy for someone to steal', 'Bulky and heavy']
    data:
      countryOfOrigin: 'Unknown'
    # TODO: bullets that are uniform across all item's products (eg max voltage, ...)

  "trc-surge-guard-34830":
    name: 'TRC Surge Guard with LCD Display, 30A'
    description: "The 30 Amp Surge Guard portable with LCD display offers more than twice the Joules of power surge protection than the previous model. Continuously monitors for voltage and amp draw and reverse polarity (miswired pedestal, elevated ground voltage). Compact and easy to use, they plug in between the power pedestal and the line cord to provide protection. Designed for all travel trailers, 5th wheels and motorhomes with 30 Amp service."
    itemSlug: 'surge-protector'
    source: 'amazon'
    sourceId: 'B00T36Q7R2'
    reviewersLiked: ['Screen with voltage and amperage draw readouts', 'Peace of mind']
    reviewersDisliked: ['Bulky and heavy']
    data:
      countryOfOrigin: 'Honduras'

  "dicor-self-leveling":
    name: 'Dicor Self-Leveling Lap Sealant'
    description: "Helps creates a watertight seal along the roof's edges, around air vents, vent pipes, air conditioners, and screw heads. Compatible with EPDM sheeting, it offers excellent adhesion to aluminum, mortar, wood, vinyl, galvanized metal, and concrete. It improves the ability to continuously seal and remain flexible. Color matched, it is UV stabilized to prevent deterioration and discoloration and will not stain or discolor any material to which it is applied. 10.3 ounce tubes, White."
    itemSlug: 'sealant'
    source: 'amazon'
    sourceId: 'B000BRF7QE'
    reviewersLiked: ['Easy to apply to horizontal surfaces', 'Long-lasting']
    reviewersDisliked: ['Some had issues with product taking a long time to dry']
    data:
      countryOfOrigin: 'Unknown'

  "dicor-non-sag":
    name: 'Dicor Non-Sag Lap Sealant'
    description: "Non sag formula can be used on vertical or horizontal surfaces. Good for windows and other seams on the sides of your RV"
    itemSlug: 'sealant'
    source: 'amazon'
    sourceId: 'B004RCSR1G'
    reviewersLiked: ['Long-lasting', 'Much better than silicone - silicon is very hard to maintain long-term', 'Adheres well']
    reviewersDisliked: ['Dries fast, making it a little harder to work with compared to typical caulk']
    data:
      countryOfOrigin: 'Unknown'

  "eternabond-roofseal-tape":
    name: 'Eternabond RoofSeal Tape'
    description: "Sealant tape for your RV roof - easy to install and extremely durable. Simple installation only requires some surface preparation before use."
    itemSlug: 'sealant'
    source: 'amazon'
    sourceId: 'B002RSIK4G'
    reviewersLiked: ['Super sticky (in a good way)', 'Long lasting (hence the name)', 'Easy to install', 'Looks good on white roofs']
    reviewersDisliked: ['Not great around curves / rounded areas']
    data:
      countryOfOrigin: 'Unknown'

  "uni-t-clamp-multimeter":
    name: 'Uni-T AC/DC Current Mini Clamp Capacitance Tester'
    description: '''
- 100A AC and DC current measurement with 1mA resolution, V.F.C function for measuring signal at varia
- 600V ac and dc voltage measurement, resistance, diode, continuity and capacitance functions
- Non-contact voltage detection with led indication, display backlight
'''
    itemSlug: 'multimeter'
    source: 'amazon'
    sourceId: 'B00O1Q2HOQ'
    reviewersLiked: []
    reviewersDisliked: []
    data:
      countryOfOrigin: 'China'

  "astroai-multimeter":
    name: 'AstroAI Digital Multimeter with Ohm Volt Amp and Diode Voltage Tester'
    description: 'Accurately measures voltage, DC current, resistance, diode, continuity and more'
    itemSlug: 'multimeter'
    source: 'amazon'
    sourceId: 'B01ISAMUA6'
    reviewersLiked: []
    reviewersDisliked: []
    data:
      countryOfOrigin: 'China'

  "camco-tastepure-with-hose":
    name: 'Camco TastePURE with Flexible Host'
    description: "This filter is hooked up to your fresh water hose outside. Removes bacteria and carbon, reduces chlorine, odor, contaminants, sediment, and particulates for better taste and healthier drinking water. Each filter lasts about 3 months."
    itemSlug: 'water-filter'
    source: 'amazon'
    sourceId: 'B0006IX87S'
    reviewersLiked: ['Easy to install', 'Doesn\'t noticeably reduce water pressure', 'Stops sediment from entering water lines and tanks']
    reviewersDisliked: ['Some (not many) experienced leakage at filter inlet', 'Water didn\'t taste good enough to some']
    data:
      countryOfOrigin: 'Unknown'

  "brita-pitcher-5-cup":
    name: 'Small Brita Pitcher (5 cup)'
    description: "Space-efficient water filter pitcher. Height 9.8\" Width 4.45\", Depth 9.37\". Filters last ~2 months. Reduces chlorine taste and odor, copper, mercury, and cadmium impurities. Good for keeping water cold and tasty, small enough to not take up too much RV fridge space."
    itemSlug: 'water-filter'
    source: 'amazon'
    sourceId: 'B015SY3W7K'
    data:
      countryOfOrigin: 'Unknown'

  "bio-pak-digester":
    name: 'Walex Bio-Pak Holding Tank Deodorizer and Waste Digester'
    description: "Deodorizes and breaks down waste and paper. Pre-packaged portion control - no measuring or pouring"
    itemSlug: 'black-tank-treatment'
    source: 'amazon'
    sourceId: 'B00157TGXY'
    reviewersLiked: ['Super easy to use', 'Reduces odors', 'Breaks down solids and toilet paper well']
    reviewersDisliked: ['Poop still smells bad']
    data:
      countryOfOrigin: 'Unknown'

  "lynx-levelers":
    name: 'Lynx Levelers (10 pack)'
    description: """
Modular designed levelers not only configure to fit any leveling function, but they also withstand tremendous weight

To use: simply set them into a pyramid shape to the desired height that the RV needs to be raised and drive onto the stack

The levelers can also be used as a support base for other stabilizing equipment"""
    itemSlug: 'leveling-blocks'
    source: 'amazon'
    sourceId: 'B0028PJ10K'
    reviewersLiked: ['Lightweight', 'Very strong', 'Convenient carrying bag']
    reviewersDisliked: ['Some wished the were wider', 'Not strong enough for a 30,000lb motorhome']
    data:
      countryOfOrigin: 'USA'

  "camco-plastic-wheel-chocks":
    name: 'Camco Plastic Wheel Chocks'
    description: "Durable hard plastic with UV inhibitors. For use with tires up to 26\" in diameter"
    itemSlug: 'chocks'
    source: 'amazon'
    sourceId: 'B00K1C1WC2'
    reviewersLiked: ['Cheap', 'Sturdy', 'Lightweight']
    reviewersDisliked: ['Crushed under steep grades and heavy weight', 'Not as good of traction on concrete']
    data:
      countryOfOrigin: 'Unknown'

  "x-chock-wheel-stabilizer":
    name: 'X-Chock Wheel Stabilizer'
    description: "Provides added stabilization and prevents tire shifts by applying opposing force to tandem tire applications"
    itemSlug: 'chocks'
    source: 'amazon'
    sourceId: 'B002XLHUQG'
    reviewersLiked: ['Much less movement when people are walking inside', 'High quality']
    reviewersDisliked: ['Still need normal chocks in addition to these', 'Somewhat heavy']
    data:
      countryOfOrigin: 'USA'

  "camco-25-drinking-water-hose":
    name: 'Camco 25\' TastePURE Drinking Water Hose'
    description: '''
- Reinforced for maximum kink resistance
- 25' long x 5/8\"ID
- Hose is made of PVC and is BPA free'''
    itemSlug: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B004ME11FS'
    reviewersLiked: ['Cheap', 'For the most part, it doesn\'t kink']
    reviewersDisliked: ['Not fully kink-proof', 'Leaked for a small percentage of users']
    data:
      countryOfOrigin: 'Unknown'

  "apex-teknor-neverkink-50":
    name: 'Apek Teknor NeverKink 50\' Drinking Water Hose'
    description: '''
- Rigid sleeve prevents kinking at the faucet
- Drinking Water Safe - Manufactured with FDA sanctioned materials
- 50' long, 5/8\"ID'''
    itemSlug: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B0001MII88'
    reviewersLiked: ['Durable', 'For the most part, it doesn\'t kink']
    reviewersDisliked: ['Not fully kink-proof', 'Leaked for a small percentage of users']
    data:
      countryOfOrigin: 'Unknown'

  "thetford-20-premium-sewer-hose":
    name: 'Thetford 20\' Premium RV Sewer Hose Kit'
    description: "Easy to mount on RV waste outlet with the Extended Grip universal bayonet mount. TPE hose prevents leaks and is uncrushable - bounces back in shape even after being run over by a car"
    itemSlug: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B01MRRSPOM'
    data:
      countryOfOrigin: 'Unknown'

  "camco-20-super-kit-sewer-hose":
    name: 'Camco 20\' Super Kit RV Sewer Hose Kit'
    description: "SUPER kit includes two 10' 18mil super heavy-duty HTS vinyl sewer hoses with pre-attached swivel fittings"
    itemSlug: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B06Y1F55J7'
    data:
      countryOfOrigin: 'Unknown'

  "camco-20-sewer-hose-support":
    name: 'Camco 20\' Sewer Hose Support'
    description: "The 20ft Sidewinder RV Sewer Hose Support by Camco lifts and cradles your sewer hose while in connection from your RV to the dump station. It keeps your sewer hose off the ground and prevents potential damage or punctures to your RV or camper sewer hose by safely nesting it in heavy duty plastic."
    itemSlug: 'sewer-hose-support'
    source: 'amazon'
    sourceId: 'B000BUU5WW'
    data:
      countryOfOrigin: 'Unknown'

  "camco-inline-water-pressure-regulator":
    name: 'Camco Inline Water Pressure Regulator'
    description: """
- Helps protect RV plumbing and hoses from high-pressure city water.
- Attaches easily with 3/4" garden hose threads.
- Durable brass construction that is drinking water safe.
- Reduces water pressure to a safe and consistent 40-50 lbs of pressure"""
    itemSlug: 'water-pressure-regulator'
    source: 'amazon'
    sourceId: 'B003BZD08U'
    data:
      countryOfOrigin: 'Unknown'

  "renator-adjustable-water-pressure-regulator":
    name: 'Renator Adjustable Water Pressure Regulator'
    description: """Adjustable up to 160 PSI with gauge to monitor current pressure."""
    itemSlug: 'water-pressure-regulator'
    source: 'amazon'
    sourceId: 'B01N7JZTYX'
    data:
      countryOfOrigin: 'Unknown'

  "renogy-100w-solar-panel-mono":
    name: 'Renogy 100W Monocrystalline Solar Panel'
    description: '''
- Withstands high wind (2400Pa) and snow loads (5400Pa); resistant aluminum frame which allows the panels to last for decades.
- Ideal output: 500 watt hours per day (depends on sunlight availability)
- 47" x 1.4" x 21.3" (6.95sqft)
'''
    itemSlug: 'solar-panel'
    source: 'amazon'
    sourceId: 'B009Z6CW7O'
    data:
      countryOfOrigin: 'USA'

  "newpowa-100w-solar-panel-poly":
    name: 'Newpowa 100W Polycrystalline Solar Panel'
    description: '''
- Diodes are pre-installed in junction box, with a pair of pre-attached 3ft MC4 Cable
- 41.8" x 1.2" x 26.6" (7.72sqft)
'''
    itemSlug: 'solar-panel'
    source: 'amazon'
    sourceId: 'B00L6LZRXM'
    data:
      countryOfOrigin: 'China'

  "power-techon-3000w-pure-sine-inverter":
    name: 'Power TechON 3000W Pure Sine Wave Power Inverter'
    description: '''
- 6000W Surge power, 3000 Continuous Power; Inverter comes with Black and Red Cables w/ Ring Terminals, Remote Switch and 3 AC sockets and 1 USB Port 5V, 2000mA and a detailed instruction manual for set-up.
- 5 Protection systems: Thermal protection, Overload protection, Over Voltage protection, Under Voltage protection, Low Voltage protection alarm. Inverter comes with an LED light to indicate the problem.
'''
    itemSlug: 'inverter'
    source: 'amazon'
    sourceId: 'B0131PZ9J2'
    data:
      countryOfOrigin: 'China'

  "giandel-2000w-modified-sine-inverter":
    name: 'GIANDEL 2000Watt Power Inverter'
    description: '''
- This is a 2000W modified sine wave power inverter provides 2000W continuous power,4000W peak power,Dual AC outlets and 1x2.4A USB port,with LED display for input voltage/output power
- Isolated Input/Output design and Multi Protections: over voltage, overload, over-current, under-voltage, overheating, short circuit protection
'''
    itemSlug: 'inverter'
    source: 'amazon'
    sourceId: 'B077HHFDZV'
    data:
      countryOfOrigin: 'China'

  "mighty-max-100ah-battery":
    name: 'Mighty Max 100Ah Lead Acid Battery'
    description: '''
- AGM. Maintenance free. No adding water
- 12.17" x 6.61" x 8.30"
'''
    itemSlug: 'batteries'
    source: 'amazon'
    sourceId: 'B077HHFDZV'
    data:
      countryOfOrigin: 'China'

  "battle-born-100ah-lithium-battery":
    name: 'Battle Born 100Ah Lithium battery'
    description: '''
- 12 volt Drop in Lead Acid Replacement
- 12.75" x 6.875" x 9"
'''
    itemSlug: 'batteries'
    source: 'amazon'
    sourceId: 'B06XX197GJ'
    reviewersLiked: ['Batteries charge fast', 'More usable amp hours', 'Reliable', 'Lightweight']
    reviewersDisliked: ['Upfront cost']
    data:
      countryOfOrigin: 'USA'

  "epever-30a-mppt-solar-charge-controller":
    name: 'EPEVER Upgraded 30A MPPT Solar Charge Controller'
    description: '''
- 99.5% Efficiency MPPT Charge Controller 30A
- Multi-function LCD displays system information intuitively
- Negative ground
'''
    itemSlug: 'charge-controller'
    source: 'amazon'
    sourceId: 'B01GMUPH0O'
    reviewersLiked: []
    reviewersDisliked: []
    data:
      countryOfOrigin: 'China'

  "renogy-wanderer-30a-pwm-charge-controller":
    name: 'Renogy Wanderer - 30A Advanced PWM'
    description: '''
- 4 Stage PWM charging (Bulk, Boost, Float, and Equalization) prevents batteries from over-charging and over-discharging. Protection against: overcharging, overload, short-circuit, and reverse polarity
- Compensates for temperature, automatically corrects charging and discharging parameters, and improves battery longevity
- Negative ground
'''
    itemSlug: 'charge-controller'
    source: 'amazon'
    sourceId: 'B00BCTLIHC'
    reviewersLiked: ['Simplicity', 'Good for small installs']
    reviewersDisliked: ['Not as efficient as MPPT']
    data:
      countryOfOrigin: 'China'

  "honda-eu2200i-2200w-inverter-generator":
    name: 'Honda EU2200i 2200W 120-Volt Super Quiet Portable Inverter Generator'
    description: '''
- Reliable Power is now at your fingertips with Honda's Inverted Generators
- So quiet, your neighbors will thank you. The EU2200i operates at 48 to 57 dBA, which is less noise than a normal conversation
- Runs 4.0 to 9.6 hours on a single tank, depending on the load
- 47 lbs
'''
    itemSlug: 'generator'
    source: 'amazon'
    sourceId: 'B079YF1HF6'
    reviewersLiked: ['Reliable', 'Lightweight', 'Very quiet']
    reviewersDisliked: ['Price']
    data:
      countryOfOrigin: 'Thailand'

  "westinghouse-igen2500-2200w-inverter-generator":
    name: 'Westinghouse iGen2500 2200W Portable Inverter Generator'
    description: '''
- Quiet Operation: the iGen2500 Utilizes a Double-Insulated Acoustic Enclosure, Asymmetrical Cooling Fans, and Low Tone Mufflers to Reduce Operating Noise (52 dBA)
- Safe for Sensitive Electronics and Strong Enough to Power All Your Household Essentials
- 48 lbs
'''
    itemSlug: 'generator'
    source: 'amazon'
    sourceId: 'B01MTGJGCN'
    reviewersLiked: ['Quiet', 'Lightweight', 'Cost-effective']
    reviewersDisliked: ['Some complaints of mistakes made by factory', 'Not as reliable as a Honda generator']
    data:
      countryOfOrigin: 'China'


module.exports = _.map products, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
