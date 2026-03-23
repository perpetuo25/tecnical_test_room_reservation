module Api
  module V1
    class RoomsController < BaseController
      def index
        render_collection(Room.order(:id), serializer: method(:room_payload))
      end

      def show
        render_resource(room, serializer: method(:room_payload))
      end

      def create
        return render_forbidden("Admin access required") unless current_user&.is_admin?

        record = Room.create!(room_params)

        render_resource(record, serializer: method(:room_payload), status: :created)
      end

      def availability
        date = Date.iso8601(params.require(:date))
        reservations = room.reservations
          .where(cancelled_at: nil)
          .where(starts_at: date.beginning_of_day..date.end_of_day)
          .order(:starts_at)

        render json: {
          data: {
            room: room_payload(room),
            date: date.iso8601,
            reservations: reservations.map { |reservation| availability_payload(reservation) }
          }
        }
      end

      private

      def room
        @room ||= Room.find(params[:id])
      end

      def current_user
        return @current_user if defined?(@current_user)

        @current_user = User.find_by(id: params[:user_id] || params[:admin_user_id])
      end

      def room_params
        params.require(:room).permit(:name, :capacity, :has_projector, :has_video_conference, :floor)
      end

      def room_payload(resource)
        resource.as_json(only: [ :id, :name, :capacity, :has_projector, :has_video_conference, :floor, :created_at, :updated_at ])
      end

      def availability_payload(resource)
        resource.as_json(
          only: [ :id, :title, :starts_at, :ends_at, :user_id ]
        )
      end
    end
  end
end
