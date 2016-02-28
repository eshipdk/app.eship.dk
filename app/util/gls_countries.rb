
module GlsCountries
  
  def get_country_code id
    hash = {
      '1' => 'FR',
      '2' => 'BE',
      '3' => 'NL',
      '4' => 'DE',
      '5' => 'IT',
      '6' => 'GB',
      '7' => 'IE',
      '8' => 'DK',
      '9' => 'GR',
      '10' => 'PT',
      '11' => 'ES',
      '19' => 'LU',
      '28' => 'NO',
      '30' => 'SE',
      '32' => 'FI',
      '38' => 'AT',
      '39' => 'CH',
      '43' => 'AD',
      '45' => 'VA',
      '46' => 'MT',
      '52' => 'TR',
      '60' => 'PL',
      '61' => 'CZ',
      '63' => 'SK',
      '64' => 'HU',
      '66' => 'RO',
      '70' => 'AL',
      '72' => 'UA',
      '73' => 'BY',
      '74' => 'MD',
      '75' => 'RU',
      '76' => 'GE',
      '77' => 'AM',
      '78' => 'AZ',
      '79' => 'KZ',
      '80' => 'TM',
      '81' => 'UZ',
      '82' => 'TJ',
      '83' => 'KG',
      '91' => 'SI',
      '92' => 'HR',
      '93' => 'BA',
      '96' => 'MK',
      '97' => 'ME',
      '98' => 'RS',
      '100' => 'BG',
      '196' => 'CY',
      '204' => 'MA',
      '208' => 'DZ',
      '212' => 'TN',
      '216' => 'LY',
      '220' => 'EG',
      '224' => 'SD',
      '228' => 'MR',
      '232' => 'ML',
      '233' => 'EE',
      '234' => 'FO',
      '236' => 'BF',
      '240' => 'NE',
      '244' => 'TD',
      '247' => 'CV',
      '248' => 'SN',
      '252' => 'GM',
      '257' => 'GW',
      '260' => 'GN',
      '264' => 'SL',
      '268' => 'LR',
      '272' => 'CI',
      '276' => 'GH',
      '280' => 'TG',
      '284' => 'BJ',
      '288' => 'NG',
      '292' => 'GI',
      '302' => 'CM',
      '304' => 'GL',
      '306' => 'CF',
      '310' => 'GQ',
      '314' => 'GA',
      '318' => 'CG',
      '322' => 'CD',
      '324' => 'RW',
      '328' => 'BI',
      '330' => 'AO',
      '334' => 'ET',
      '336' => 'ER',
      '338' => 'DJ',
      '342' => 'SO',
      '346' => 'KE',
      '350' => 'UG',
      '352' => 'IS',
      '355' => 'SC',
      '366' => 'MZ',
      '370' => 'MG',
      '373' => 'MU',
      '378' => 'ZM',
      '382' => 'ZW',
      '386' => 'MW',
      '388' => 'ZA',
      '389' => 'NA',
      '391' => 'BW',
      '393' => 'SZ',
      '395' => 'LS',
      '400' => 'US',
      '404' => 'CA',
      '410' => 'KR',
      '412' => 'MX',
      '413' => 'BM',
      '416' => 'GT',
      '421' => 'BZ',
      '424' => 'HN',
      '428' => 'LV',
      '432' => 'NI',
      '440' => 'LT',
      '442' => 'PA',
      '446' => 'AI',
      '449' => 'KN',
      '452' => 'HT',
      '453' => 'BS',
      '456' => 'DO',
      '457' => 'VI',
      '459' => 'AG',
      '460' => 'DM',
      '463' => 'KY',
      '464' => 'JM',
      '465' => 'LC',
      '467' => 'VC',
      '468' => 'VG',
      '469' => 'BB',
      '470' => 'MS',
      '472' => 'TT',
      '473' => 'GD',
      '474' => 'AW',
      '478' => 'AN',
      '480' => 'CO',
      '484' => 'VE',
      '488' => 'GY',
      '492' => 'MC',
      '500' => 'EC',
      '508' => 'BR',
      '512' => 'CL',
      '516' => 'BO',
      '520' => 'PY',
      '524' => 'UY',
      '528' => 'AR',
      '604' => 'LB',
      '608' => 'SY',
      '612' => 'IQ',
      '616' => 'IR',
      '624' => 'IL',
      '628' => 'JO',
      '632' => 'SA',
      '636' => 'KW',
      '638' => 'RE',
      '640' => 'BH',
      '644' => 'QA',
      '647' => 'AE',
      '649' => 'OM',
      '653' => 'YE',
      '662' => 'PK',
      '664' => 'IN',
      '666' => 'BD',
      '667' => 'MV',
      '669' => 'LK',
      '672' => 'NP',
      '674' => 'SM',
      '675' => 'BT',
      '676' => 'MM',
      '680' => 'TH',
      '684' => 'LA',
      '690' => 'VN',
      '696' => 'KH',
      '700' => 'ID',
      '701' => 'MY',
      '703' => 'BN',
      '706' => 'SG',
      '708' => 'PH',
      '716' => 'MN',
      '720' => 'CN',
      '732' => 'JP',
      '736' => 'TW',
      '740' => 'HK',
      '743' => 'MO',
      '800' => 'AU',
      '801' => 'PG',
      '804' => 'NZ',
      '809' => 'NC',
      '811' => 'WF',
      '815' => 'FJ',
      '816' => 'VU',
      '820' => 'MP',
      '822' => 'PF',
      '823' => 'FM',
      '824' => 'MH',
      '825' => 'PW',
    }
    hash[id.to_s]
  end
  
  
  
  
end