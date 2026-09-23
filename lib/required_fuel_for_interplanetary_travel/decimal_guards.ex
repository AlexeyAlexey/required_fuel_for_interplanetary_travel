defmodule DecimalGuards do
  # A decimal is > 0 if it is a Decimal struct, its sign is 1, and its coefficient is not 0
  defguard is_positive_decimal(term)
           when is_map(term) and
                  :erlang.map_get(:__struct__, term) == Decimal and
                  :erlang.map_get(:sign, term) == 1 and
                  :erlang.map_get(:coef, term) != 0
end
