# name: discourse-solved-cache
# about: Adds latest 5 accepted answers to category serializer, cached every minute
# version: 0.1
# authors: Arpit Jalan

after_initialize do

  require_dependency 'category_list_serializer'

  class ::CategoryListSerializer
    attributes :solved_answers

    def solved_answers
      Rails.cache.fetch("latest_solved_answers", expires_in: 1.minute){
        solved_answers = {}
        custom_field = TopicCustomField.includes(:topic => :category)
                                 .joins("INNER JOIN posts ON posts.id = topic_custom_fields.value::int8")
                                 .joins("INNER JOIN users ON users.id = posts.user_id")
                                 .select('topic_custom_fields.*, posts.id post_id, posts.created_at post_created_at, users.username username')
                                 .where(name: 'accepted_answer_post_id')
                                 .limit(5)
                                 .order("DATE(topic_custom_fields.created_at)")

        custom_field.each_with_index do |field, index|
          solved_answers[index] = {username: field.username, title: field.topic.title, category_name: field.topic.category.name, post_created_at: field.post_created_at}
        end
        solved_answers
      }
    end
  end
end
