module Api
  module V1
    class UsersController < BaseController
      def index
        render_collection(User.order(:id), serializer: method(:user_payload))
      end

      def show
        render_resource(user, serializer: method(:user_payload))
      end

      def create
        record = User.create!(user_params)

        render_resource(record, serializer: method(:user_payload), status: :created)
      end

      private

      def user
        @user ||= User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:name, :email, :department, :max_capacity_allowed, :is_admin)
      end

      def user_payload(resource)
        resource.as_json(only: [ :id, :name, :email, :department, :max_capacity_allowed, :is_admin, :created_at, :updated_at ])
      end
    end
  end
end
