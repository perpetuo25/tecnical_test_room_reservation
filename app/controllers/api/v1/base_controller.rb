module Api
  module V1
    class BaseController < ApplicationController
      DEFAULT_PAGE = 1
      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 100

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def paginate(scope)
        page = params.fetch(:page, DEFAULT_PAGE).to_i
        per_page = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i

        page = DEFAULT_PAGE if page < 1
        per_page = DEFAULT_PER_PAGE if per_page < 1
        per_page = [ per_page, MAX_PER_PAGE ].min

        total_count = scope.count
        records = scope.offset((page - 1) * per_page).limit(per_page)

        [ records, {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page).ceil
        } ]
      end

      def render_collection(scope, serializer: nil, status: :ok)
        records, meta = paginate(scope)

        render json: {
          data: serialize(records, serializer),
          meta: meta
        }, status: status
      end

      def render_resource(resource, serializer: nil, status: :ok)
        render json: { data: serialize(resource, serializer) }, status: status
      end

      def render_error(message, status:, details: nil)
        payload = { error: { message: message } }
        payload[:error][:details] = details if details.present?

        render json: payload, status: status
      end

      def serialize(resource, serializer)
        serializer ? serializer.call(resource) : resource.as_json
      end

      def render_not_found(exception)
        render_error(exception.message, status: :not_found)
      end

      def render_unprocessable_entity(exception)
        render_error(
          "Validation failed",
          status: :unprocessable_entity,
          details: exception.record.errors.full_messages
        )
      end

      def render_bad_request(exception)
        render_error(exception.message, status: :bad_request)
      end
    end
  end
end
