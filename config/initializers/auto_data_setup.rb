# Auto data setup for production environment
Rails.application.config.after_initialize do
  if Rails.env.production? && defined?(Rails::Server)
    begin
      # Check if basic college data exists
      if ActiveRecord::Base.connection.table_exists?('conditions') && Condition.count < 10
        Rails.logger.info "=== Auto Data Setup: Starting ==="
        
        # Create basic college data
        sample_colleges = [
          {college: 'Harvard University', state: 'Massachusetts', tuition: 54000, students: 22000, privateorpublic: 'Private', 
           GPA: 3.9, acceptance_rate: 5.0, graduation_rate: 98.0, city: 'Cambridge', Division: 'I'},
          {college: 'Stanford University', state: 'California', tuition: 56000, students: 17000, privateorpublic: 'Private',
           GPA: 3.8, acceptance_rate: 4.3, graduation_rate: 97.0, city: 'Stanford', Division: 'I'},
          {college: 'MIT', state: 'Massachusetts', tuition: 53000, students: 11500, privateorpublic: 'Private',
           GPA: 3.9, acceptance_rate: 6.7, graduation_rate: 96.0, city: 'Cambridge', Division: 'III'},
          {college: 'University of California-Berkeley', state: 'California', tuition: 43000, students: 45000, privateorpublic: 'Public',
           GPA: 3.7, acceptance_rate: 16.8, graduation_rate: 92.0, city: 'Berkeley', Division: 'I'},
          {college: 'Yale University', state: 'Connecticut', tuition: 59000, students: 13500, privateorpublic: 'Private',
           GPA: 3.9, acceptance_rate: 6.5, graduation_rate: 97.0, city: 'New Haven', Division: 'I'},
          {college: 'Princeton University', state: 'New Jersey', tuition: 56000, students: 5400, privateorpublic: 'Private',
           GPA: 3.9, acceptance_rate: 5.8, graduation_rate: 97.0, city: 'Princeton', Division: 'I'},
          {college: 'Columbia University', state: 'New York', tuition: 61000, students: 31000, privateorpublic: 'Private',
           GPA: 3.8, acceptance_rate: 6.1, graduation_rate: 95.0, city: 'New York', Division: 'I'},
          {college: 'University of Chicago', state: 'Illinois', tuition: 59000, students: 17000, privateorpublic: 'Private',
           GPA: 3.8, acceptance_rate: 7.4, graduation_rate: 95.0, city: 'Chicago', Division: 'III'},
          {college: 'University of Pennsylvania', state: 'Pennsylvania', tuition: 58000, students: 25000, privateorpublic: 'Private',
           GPA: 3.8, acceptance_rate: 8.4, graduation_rate: 96.0, city: 'Philadelphia', Division: 'I'},
          {college: 'University of Michigan-Ann Arbor', state: 'Michigan', tuition: 51000, students: 48000, privateorpublic: 'Public',
           GPA: 3.7, acceptance_rate: 23.0, graduation_rate: 93.0, city: 'Ann Arbor', Division: 'I'},
          {college: 'Ohio State University', state: 'Ohio', tuition: 32000, students: 65000, privateorpublic: 'Public',
           GPA: 3.6, acceptance_rate: 54.0, graduation_rate: 84.0, city: 'Columbus', Division: 'I'},
          {college: 'University of Texas at Austin', state: 'Texas', tuition: 40000, students: 51000, privateorpublic: 'Public',
           GPA: 3.7, acceptance_rate: 32.0, graduation_rate: 87.0, city: 'Austin', Division: 'I'},
          {college: 'University of Florida', state: 'Florida', tuition: 28000, students: 52000, privateorpublic: 'Public',
           GPA: 3.6, acceptance_rate: 30.0, graduation_rate: 90.0, city: 'Gainesville', Division: 'I'},
          {college: 'New York University', state: 'New York', tuition: 58000, students: 51000, privateorpublic: 'Private',
           GPA: 3.7, acceptance_rate: 16.0, graduation_rate: 85.0, city: 'New York', Division: 'I'},
          {college: 'Boston University', state: 'Massachusetts', tuition: 58000, students: 35000, privateorpublic: 'Private',
           GPA: 3.7, acceptance_rate: 19.0, graduation_rate: 87.0, city: 'Boston', Division: 'I'}
        ]
        
        created_count = 0
        sample_colleges.each do |college_data|
          unless Condition.find_by(college: college_data[:college])
            Condition.create!(college_data)
            created_count += 1
          end
        end
        
        Rails.logger.info "=== Auto Data Setup: Created #{created_count} colleges ==="
        
        # Add comments if needed
        if Condition.where.not(comment: [nil, '']).count < 5
          require_relative '../../lib/college_comment_generator'
          
          comment_count = 0
          Condition.where(comment: [nil, '']).limit(20).each do |college|
            comment_data = {
              students: college.students,
              acceptance_rate: college.acceptance_rate,
              ownership: college.privateorpublic,
              school_type: college.school_type
            }
            
            comment = CollegeCommentGenerator.generate_comment_for_college(college.college, comment_data)
            college.update(comment: comment)
            comment_count += 1
          end
          
          Rails.logger.info "=== Auto Data Setup: Added #{comment_count} comments ==="
        end
        
        Rails.logger.info "=== Auto Data Setup: Completed ==="
        Rails.logger.info "Total colleges: #{Condition.count}"
      end
    rescue => e
      Rails.logger.error "Auto data setup failed: #{e.message}"
    end
  end
end