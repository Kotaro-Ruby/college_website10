module SeoHelper
  def set_meta_tags(options = {})
    defaults = {
      site_name: 'College Spark',
      reverse: true,
      separator: '|',
      description: '6,300校以上のアメリカの大学から、あなたに最適な大学を見つけよう。学費・合格率・専攻・奨学金など詳細情報で留学を完全サポート',
      keywords: default_keywords,
      canonical: request.original_url,
      og: default_og_tags,
      twitter: default_twitter_tags
    }
    
    options = defaults.deep_merge(options)
    
    # タイトル設定
    if options[:title].present?
      content_for(:title, build_title(options[:title], options[:site_name], options[:reverse], options[:separator]))
    end
    
    # メタ説明文
    if options[:description].present?
      content_for(:description, truncate(options[:description], length: 155))
    end
    
    # キーワード
    if options[:keywords].present?
      keywords = options[:keywords].is_a?(Array) ? options[:keywords].join(', ') : options[:keywords]
      content_for(:keywords, keywords)
    end
    
    # Canonical URL
    if options[:canonical].present?
      content_for(:canonical_url, options[:canonical])
    end
    
    # OGP
    if options[:og].present?
      content_for(:og_title, options[:og][:title] || options[:title])
      content_for(:og_description, options[:og][:description] || options[:description])
      content_for(:og_image, options[:og][:image]) if options[:og][:image]
      content_for(:og_url, options[:og][:url] || options[:canonical])
    end
    
    # Twitter Cards
    if options[:twitter].present?
      content_for(:twitter_title, options[:twitter][:title] || options[:og][:title] || options[:title])
      content_for(:twitter_description, options[:twitter][:description] || options[:og][:description] || options[:description])
      content_for(:twitter_image, options[:twitter][:image] || options[:og][:image]) if options[:twitter][:image] || options[:og][:image]
    end
  end
  
  def generate_structured_data(type, data = {})
    case type
    when :college
      college_structured_data(data)
    when :article
      article_structured_data(data)
    when :breadcrumb
      breadcrumb_structured_data(data)
    when :faq
      faq_structured_data(data)
    when :organization
      organization_structured_data(data)
    else
      nil
    end
  end
  
  private
  
  def build_title(title, site_name, reverse, separator)
    if reverse
      "#{title} #{separator} #{site_name}"
    else
      "#{site_name} #{separator} #{title}"
    end
  end
  
  def default_keywords
    [
      'アメリカ大学', '海外大学', '大学留学', 'アメリカ留学', 
      '大学検索', 'College Search', '学費', '奨学金',
      'SAT', 'TOEFL', '合格率', '留学準備', 'アメリカ大学ランキング',
      'コミュニティカレッジ', '州立大学', '私立大学', 'リベラルアーツ',
      'STEM', 'ビジネススクール', 'エンジニアリング'
    ].join(', ')
  end
  
  def default_og_tags
    {
      type: 'website',
      site_name: 'College Spark',
      locale: 'ja_JP'
    }
  end
  
  def default_twitter_tags
    {
      card: 'summary_large_image',
      site: '@college__spark',
      creator: '@college__spark'
    }
  end
  
  def college_structured_data(college)
    {
      '@context': 'https://schema.org',
      '@type': 'CollegeOrUniversity',
      name: college[:name],
      url: college[:url],
      address: {
        '@type': 'PostalAddress',
        addressLocality: college[:city],
        addressRegion: college[:state],
        addressCountry: 'US'
      },
      description: college[:description],
      numberOfStudents: {
        '@type': 'QuantitativeValue',
        value: college[:students]
      },
      tuitionAndFees: {
        '@type': 'MonetaryAmount',
        currency: 'USD',
        value: college[:tuition]
      }
    }.to_json.html_safe
  end
  
  def article_structured_data(article)
    {
      '@context': 'https://schema.org',
      '@type': 'Article',
      headline: article[:title],
      description: article[:description],
      author: {
        '@type': 'Person',
        name: article[:author] || 'College Spark'
      },
      datePublished: article[:published_at]&.iso8601,
      dateModified: article[:updated_at]&.iso8601,
      publisher: organization_data,
      mainEntityOfPage: {
        '@type': 'WebPage',
        '@id': article[:url]
      }
    }.to_json.html_safe
  end
  
  def breadcrumb_structured_data(items)
    {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      itemListElement: items.map.with_index do |item, index|
        {
          '@type': 'ListItem',
          position: index + 1,
          name: item[:name],
          item: item[:url]
        }
      end
    }.to_json.html_safe
  end
  
  def faq_structured_data(faqs)
    {
      '@context': 'https://schema.org',
      '@type': 'FAQPage',
      mainEntity: faqs.map do |faq|
        {
          '@type': 'Question',
          name: faq[:question],
          acceptedAnswer: {
            '@type': 'Answer',
            text: faq[:answer]
          }
        }
      end
    }.to_json.html_safe
  end
  
  def organization_structured_data(data = {})
    {
      '@context': 'https://schema.org',
      '@type': 'Organization',
      name: 'College Spark',
      url: 'https://college-spark.com',
      logo: 'https://college-spark.com/logo.png',
      description: 'アメリカの大学検索・比較サイト',
      sameAs: [
        'https://twitter.com/college__spark',
        'https://www.instagram.com/college_spark_official'
      ],
      contactPoint: {
        '@type': 'ContactPoint',
        contactType: 'customer service',
        availableLanguage: ['ja', 'en']
      }
    }.merge(data).to_json.html_safe
  end
  
  def organization_data
    {
      '@type': 'Organization',
      name: 'College Spark',
      url: 'https://college-spark.com',
      logo: {
        '@type': 'ImageObject',
        url: 'https://college-spark.com/logo.png'
      }
    }
  end
end