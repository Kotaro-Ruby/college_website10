module UniversitiesHelper
  def university_image(university_name, options = {})
    unsplash_service = UnsplashService.new
    photo_data = unsplash_service.get_cached_photo(university_name, options[:country])

    if photo_data
      content_tag :div, class: "university-image-container" do
        image = image_tag(photo_data[:url],
                         alt: university_name,
                         class: options[:class] || "university-image",
                         loading: "lazy")

        attribution = content_tag :div, class: "image-attribution" do
          link_to photo_data[:unsplash_url], target: "_blank", rel: "noopener" do
            "Photo by #{photo_data[:photographer]} on Unsplash"
          end
        end

        image + attribution
      end
    else
      # デフォルト画像を表示
      content_tag :div, class: "university-image-placeholder" do
        content_tag :i, "", class: "fas fa-university"
      end
    end
  end

  def university_thumbnail(university_name, options = {})
    unsplash_service = UnsplashService.new
    photo_data = unsplash_service.get_cached_photo(university_name, options[:country])

    if photo_data
      image_tag(photo_data[:thumb_url],
                alt: university_name,
                class: options[:class] || "university-thumbnail",
                loading: "lazy")
    else
      content_tag :div, class: "university-thumb-placeholder" do
        content_tag :i, "", class: "fas fa-university"
      end
    end
  end
end
