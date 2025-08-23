# WikiCommons APIで取得した画像URLをデータベースに更新するスクリプト
# 本番環境でのデプロイ時に実行される

puts "Updating Australian university images from WikiCommons..."

# 画像データ（WikiCommons APIで取得済みのもの）
image_updates = {
  "Charles Sturt University" => {
    images: [
      "/images/au/universities/charles-sturt-university.jpg",
      "/images/au/universities/charles-sturt-university-2.jpg",
      "/images/au/universities/charles-sturt-university-3.jpg"
    ],
    credits: [
      "Bidgee / Wikimedia Commons / CC BY-SA 3.0",
      "Bidgee / Wikimedia Commons / CC BY-SA 3.0",
      "Pru.mitchell / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "The University of Queensland" => {
    images: [
      "/images/au/universities/the-university-of-queensland.jpg",
      "/images/au/universities/the-university-of-queensland-2.jpg",
      "/images/au/universities/the-university-of-queensland-3.jpg"
    ],
    credits: [
      "Kgbo / Wikimedia Commons / CC BY-SA 4.0",
      "Kgbo / Wikimedia Commons / CC BY-SA 4.0",
      "Kgbo / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "UNSW" => {
    images: [
      "/images/au/universities/unsw.jpg",
      "/images/au/universities/unsw-2.jpg",
      "/images/au/universities/unsw-3.jpg"
    ],
    credits: [
      "Voyager2 / Wikimedia Commons / CC BY-SA 3.0 de",
      "Max Dupain, UNSW Archives CN945/19/4 / Wikimedia Commons / CC BY-SA 4.0",
      "Sardaka / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "University of Technology Sydney" => {
    images: [
      "/images/au/universities/university-of-technology-sydney.jpg",
      "/images/au/universities/university-of-technology-sydney-2.jpg",
      "/images/au/universities/university-of-technology-sydney-3.jpg"
    ],
    credits: [
      "Summerdrought / Wikimedia Commons / CC BY-SA 4.0",
      "Hpeterswald / Wikimedia Commons / CC BY-SA 4.0",
      "Hpeterswald / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "University of Wollongong" => {
    images: [
      "/images/au/universities/university-of-wollongong.jpg",
      "/images/au/universities/university-of-wollongong-2.jpg"
    ],
    credits: [
      "Jason Tong / Wikimedia Commons / CC BY 2.0",
      "Jason Tong / Wikimedia Commons / CC BY 2.0"
    ]
  },
  "Federation University Australia" => {
    images: [
      "/images/au/universities/federation-university-australia.jpg",
      "/images/au/universities/federation-university-australia-2.jpg",
      "/images/au/universities/federation-university-australia-3.jpg"
    ],
    credits: [
      "Dgraham1980 / Wikimedia Commons / CC BY-SA 3.0",
      "Dgraham1980 / Wikimedia Commons / CC BY-SA 3.0",
      "Matt / Wikimedia Commons / CC BY 2.0"
    ]
  },
  "The University of Newcastle" => {
    images: [
      "/images/au/universities/the-university-of-newcastle.jpg",
      "/images/au/universities/the-university-of-newcastle-2.jpg",
      "/images/au/universities/the-university-of-newcastle-3.jpg"
    ],
    credits: [
      "Wikimedia Commons / CC BY-SA 4.0",
      "Wikimedia Commons / CC BY-SA 4.0",
      "Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "La Trobe University" => {
    images: [
      "/images/au/universities/la-trobe-university.jpg",
      "/images/au/universities/la-trobe-university-2.jpg",
      "/images/au/universities/la-trobe-university-3.jpg"
    ],
    credits: [
      "Wikimedia Commons / CC BY-SA 4.0",
      "Wikimedia Commons / CC BY-SA 4.0",
      "Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "James Cook University" => {
    images: [
      "/images/au/universities/james-cook-university.jpg"
    ],
    credits: [
      "Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "Victoria University" => {
    images: [
      "/images/au/universities/victoria-university.jpg",
      "/images/au/universities/victoria-university-2.jpg",
      "/images/au/universities/victoria-university-3.jpg"
    ],
    credits: [
      "Wikimedia Commons / CC BY-SA 4.0",
      "Wikimedia Commons / CC BY-SA 4.0",
      "Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "Murdoch University" => {
    images: [
      "/images/au/universities/murdoch-university.jpg",
      "/images/au/universities/murdoch-university-2.jpg",
      "/images/au/universities/murdoch-university-3.jpg"
    ],
    credits: [
      "Wikimedia Commons / CC BY-SA 4.0",
      "Wikimedia Commons / CC BY-SA 4.0",
      "Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "The University of Western Australia" => {
    images: [
      "/images/au/universities/the-university-of-western-australia.jpg",
      "/images/au/universities/the-university-of-western-australia-2.jpg",
      "/images/au/universities/the-university-of-western-australia-3.jpg"
    ],
    credits: [
      "Jason Tong / Wikimedia Commons / CC BY 2.0",
      "Chris.sherlock2 / Wikimedia Commons / CC BY-SA 4.0",
      "Chris.sherlock2 / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "CQUniversity Australia" => {
    images: [
      "/images/au/universities/cquniversity-australia.jpg",
      "/images/au/universities/cquniversity-australia-2.jpg",
      "/images/au/universities/cquniversity-australia-3.jpg"
    ],
    credits: [
      "RegionalQueenslander / Wikimedia Commons / CC BY-SA 4.0",
      "RegionalQueenslander / Wikimedia Commons / CC BY-SA 4.0",
      "RegionalQueenslander / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "Griffith University" => {
    images: [
      "/images/au/universities/griffith-university.jpg",
      "/images/au/universities/griffith-university-2.jpg",
      "/images/au/universities/griffith-university-3.jpg"
    ],
    credits: [
      "Orderinchaos / Wikimedia Commons / CC BY-SA 4.0",
      "Orderinchaos / Wikimedia Commons / CC BY-SA 4.0",
      "Glyn Baker / Wikimedia Commons / CC BY-SA 2.0"
    ]
  },
  "University of Southern Queensland" => {
    images: [
      "/images/au/universities/university-of-southern-queensland.jpg"
    ],
    credits: [
      "Shiftchange / Wikimedia Commons / CC0"
    ]
  },
  "Edith Cowan University" => {
    images: [
      "/images/au/universities/edith-cowan-university.jpg",
      "/images/au/universities/edith-cowan-university-2.jpg",
      "/images/au/universities/edith-cowan-university-3.jpg"
    ],
    credits: [
      "Orderinchaos / Wikimedia Commons / CC BY-SA 4.0",
      "Orderinchaos / Wikimedia Commons / CC BY-SA 4.0",
      "Orderinchaos / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "Charles Darwin University" => {
    images: [
      "/images/au/universities/charles-darwin-university.jpg",
      "/images/au/universities/charles-darwin-university-2.jpg",
      "/images/au/universities/charles-darwin-university-3.jpg"
    ],
    credits: [
      "Cayambe / Wikimedia Commons / CC BY-SA 4.0",
      "Cayambe / Wikimedia Commons / CC BY-SA 4.0",
      "Cayambe / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "Curtin University" => {
    images: [
      "/images/au/universities/curtin-university.jpg",
      "/images/au/universities/curtin-university-2.jpg",
      "/images/au/universities/curtin-university-3.jpg"
    ],
    credits: [
      "Orderinchaos / Wikimedia Commons / CC BY-SA 4.0",
      "Orderinchaos / Wikimedia Commons / CC BY-SA 4.0",
      "Orderinchaos / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "Western Sydney University" => {
    images: [
      "/images/au/universities/western-sydney-university.jpg",
      "/images/au/universities/western-sydney-university-2.jpg",
      "/images/au/universities/western-sydney-university-3.jpg"
    ],
    credits: [
      "Chris.sherlock2 / Wikimedia Commons / CC BY-SA 4.0",
      "Chris.sherlock2 / Wikimedia Commons / CC BY-SA 4.0",
      "Chris.sherlock2 / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "The Australian National University" => {
    images: [
      "/images/au/universities/the-australian-national-university.jpg",
      "/images/au/universities/the-australian-national-university-2.jpg",
      "/images/au/universities/the-australian-national-university-3.jpg"
    ],
    credits: [
      "Alvinz / Wikimedia Commons / CC BY-SA 4.0",
      "Alvinz / Wikimedia Commons / CC BY-SA 4.0",
      "Nick-D / Wikimedia Commons / CC BY-SA 3.0"
    ]
  },
  "University of the Sunshine Coast" => {
    images: [
      "/images/au/universities/university-of-the-sunshine-coast.jpg"
    ],
    credits: [
      "Uscjkirklan / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "The University of Adelaide" => {
    images: [
      "/images/au/universities/the-university-of-adelaide.jpg",
      "/images/au/universities/the-university-of-adelaide-2.jpg",
      "/images/au/universities/the-university-of-adelaide-3.jpg"
    ],
    credits: [
      "Andrew Shipway / Wikimedia Commons / CC BY-SA 2.0",
      "LinhChameleon / Wikimedia Commons / CC BY-SA 2.0",
      "Michael Coghlan / Wikimedia Commons / CC BY-SA 2.0"
    ]
  },
  "The University of New England" => {
    images: [
      "/images/au/universities/the-university-of-new-england.jpg",
      "/images/au/universities/the-university-of-new-england-2.jpg",
      "/images/au/universities/the-university-of-new-england-3.jpg"
    ],
    credits: [
      "Iain Tullis / Wikimedia Commons / CC BY-SA 2.0",
      "Ian Paterson / Wikimedia Commons / CC BY-SA 2.0",
      "David Lally / Wikimedia Commons / CC BY-SA 2.0"
    ]
  },
  "University of South Australia" => {
    images: [
      "/images/au/universities/university-of-south-australia.jpg",
      "/images/au/universities/university-of-south-australia-2.jpg",
      "/images/au/universities/university-of-south-australia-3.jpg"
    ],
    credits: [
      "Rexness / Wikimedia Commons / CC BY-SA 2.0",
      "Chris.sherlock2 / Wikimedia Commons / CC BY-SA 4.0",
      "Chris.sherlock2 / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "University of Tasmania" => {
    images: [
      "/images/au/universities/university-of-tasmania.jpg",
      "/images/au/universities/university-of-tasmania-2.jpg",
      "/images/au/universities/university-of-tasmania-3.jpg"
    ],
    credits: [
      "TaswegianSchnapps / Wikimedia Commons / CC BY-SA 4.0",
      "Gary Houston / Wikimedia Commons / CC0",
      "Gary Houston / Wikimedia Commons / CC0"
    ]
  },
  "Deakin University" => {
    images: [
      "/images/au/universities/deakin-university.jpg",
      "/images/au/universities/deakin-university-2.jpg",
      "/images/au/universities/deakin-university-3.jpg"
    ],
    credits: [
      "Longhair / Wikimedia Commons / Public domain",
      "Steve Shook / Wikimedia Commons / CC BY 2.0",
      "Marcus Wong / Wikimedia Commons / CC BY-SA 3.0"
    ]
  },
  "Swinburne University of Technology" => {
    images: [
      "/images/au/universities/swinburne-university-of-technology.jpg",
      "/images/au/universities/swinburne-university-of-technology-2.jpg",
      "/images/au/universities/swinburne-university-of-technology-3.png"
    ],
    credits: [
      "Medelam / Wikimedia Commons / CC BY-SA 4.0",
      "GarryRasmussen1 / Wikimedia Commons / CC0",
      "GarryRasmussen1 / Wikimedia Commons / Public domain"
    ]
  },
  "The University of Melbourne" => {
    images: [
      "/images/au/universities/the-university-of-melbourne.jpg",
      "/images/au/universities/the-university-of-melbourne-2.jpg",
      "/images/au/universities/the-university-of-melbourne-3.jpg"
    ],
    credits: [
      "Polly clip / Wikimedia Commons / CC BY-SA 3.0",
      "Polly clip / Wikimedia Commons / CC BY-SA 3.0",
      "Gracchus250 / Wikimedia Commons / CC BY-SA 4.0"
    ]
  },
  "University of Canberra" => {
    images: [
      "/images/au/universities/university-of-canberra.jpg",
      "/images/au/universities/university-of-canberra-2.jpg"
    ],
    credits: [
      "Alvinz / Wikimedia Commons / CC BY-SA 4.0",
      "Alvinz / Wikimedia Commons / CC0"
    ]
  }
}

# データベースを更新
success_count = 0
error_count = 0

image_updates.each do |university_name, data|
  university = AuUniversity.find_by(name: university_name)
  
  if university
    begin
      university.update!(
        images: data[:images].to_json,
        image_credits: data[:credits].to_json
      )
      success_count += 1
      puts "✓ Updated: #{university_name}"
    rescue => e
      error_count += 1
      puts "✗ Error updating #{university_name}: #{e.message}"
    end
  else
    error_count += 1
    puts "✗ Not found: #{university_name}"
  end
end

puts "\n" + "=" * 60
puts "Update completed!"
puts "Success: #{success_count} universities"
puts "Errors: #{error_count} universities" if error_count > 0