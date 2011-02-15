module Slingshot
  module Model

    module Search

      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods

        if base.respond_to?(:after_save) && base.respond_to?(:after_destroy)
          base.send :after_save,    :update_index
          base.send :after_destroy, :update_index
        end

        base.create_index
      end

      module ClassMethods

        def search(query=nil, options={}, &block)
          old_wrapper = Slingshot::Configuration.wrapper
          Slingshot::Configuration.wrapper self
          index = model_name.plural
          sort  = options[:order] || options[:sort]
          sort  = Array(sort)
          unless block_given?
            s = Slingshot::Search::Search.new(index, options)
            s.query { string query }
            s.sort do
              sort.each do |t|
                field_name, direction = t.split(' ')
                field_name.include?('.') ? field(field_name, direction) : send(field_name, direction)
              end
            end unless sort.empty?
            s.perform.results
          else
            s = Slingshot::Search::Search.new(index, options, &block).perform.results
          end
        ensure
          Slingshot::Configuration.wrapper old_wrapper
        end

        def create_index
          Index.new(model_name.plural).create
        end

        def mode
          :searchable
        end

      end

      module InstanceMethods

        def update_index
          if destroyed?
            Index.new(self.class.model_name.plural).remove self.class.model_name.plural, self
          else
            Index.new(self.class.model_name.plural).store  self.class.model_name.plural, self
          end
        end

        def to_indexed_json
          self.serializable_hash.to_json
        end


      end


      extend ClassMethods
    end

  end
end
