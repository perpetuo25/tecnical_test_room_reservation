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
        record = Room.create!(room_params)

        render_resource(record, serializer: method(:room_payload), status: :created)
      end

      private

      def room
        @room ||= Room.find(params[:id])
      end

      def room_params
        params.require(:room).permit(:name, :capacity, :has_projector, :has_video_conference, :floor)
      end

      def room_payload(resource)
        resource.as_json(only: [ :id, :name, :capacity, :has_projector, :has_video_conference, :floor, :created_at, :updated_at ])
      end
    end
  end
end
