module Api
  module V1
    class ReservationsController < BaseController
      def index
        render_collection(Reservation.includes(:room, :user).order(:starts_at, :id), serializer: method(:reservation_payload))
      end

      def show
        render_resource(reservation, serializer: method(:reservation_payload))
      end

      def create
        records = create_reservations
        payload = records.many? ? records.map { |record| reservation_payload(record) } : reservation_payload(records.first)

        render json: { data: payload }, status: :created
      end

      def cancel
        reservation.cancel!

        render_resource(reservation, serializer: method(:reservation_payload))
      end

      private

      def reservation
        @reservation ||= Reservation.includes(:room, :user).find(params[:id])
      end

      def reservation_params
        params.require(:reservation).permit(
          :room_id,
          :user_id,
          :title,
          :starts_at,
          :ends_at,
          :recurring,
          :recurring_until
        )
      end

      def create_reservations
        if reservation_params[:recurring].present?
          Reservations::RecurringCreator.new(reservation_params).call
        else
          [ Reservation.create!(reservation_params) ]
        end
      end

      def reservation_payload(resource)
        resource.as_json(
          only: [ :id, :room_id, :user_id, :title, :starts_at, :ends_at, :recurring, :recurring_until, :cancelled_at, :created_at, :updated_at ],
          include: {
            room: { only: [ :id, :name, :capacity, :floor ] },
            user: { only: [ :id, :name, :email, :department, :is_admin ] }
          }
        )
      end
    end
  end
end
