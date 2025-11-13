# Base class for MongoDB documents
# Since we're using the mongo driver directly (Mongoid not compatible with Rails 8.1),
# this provides a base structure for models
class ApplicationDocument
  class << self
    def collection_name
      @collection_name ||= name.underscore.pluralize
    end

    def collection
      MONGODB_DB[collection_name]
    end

    def all
      collection.find.to_a
    end

    def find(id)
      begin
        object_id = id.is_a?(BSON::ObjectId) ? id : BSON::ObjectId(id)
        collection.find(_id: object_id).first
      rescue BSON::ObjectId::Invalid
        nil
      end
    end

    def create(attributes = {})
      result = collection.insert_one(attributes.merge(created_at: Time.current, updated_at: Time.current))
      find(result.inserted_id.to_s)
    end

    def where(query = {})
      collection.find(query).to_a
    end
  end
end

