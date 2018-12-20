defmodule KEYGENERATION do

    def generate do
      private_key = :crypto.strong_rand_bytes(32)
      case valid?(private_key) do
        true  -> private_key
        false -> generate()
      end
      public_key = to_public_key(private_key)
      to_public_hash(public_key)
      [private_key |> Base.encode16() , public_key |> Base.encode16()]
    end
  
    defp valid?(key) when is_binary(key) do
      key
      |> :binary.decode_unsigned
      |> valid?
    end
  
    @n :binary.decode_unsigned(<<
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE,
    0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B,
    0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x41
    >>)
  
    defp valid?(key) when key > 1 and key < @n, do: true
    defp valid?(_), do: false
  
    # transform private key into a public key with the help of elliptic curve cryptography
    # sixty five byte binary representing public key
    def to_public_key(private_key) do
      public_key = :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), private_key)
      |> elem(0)
      public_key
    end
  
    def hash(data, algorithm), do: :crypto.hash(algorithm, data)
  
    def to_public_hash(key) do
      public_hash = key
      |> hash(:sha256)
      |> hash(:ripemd160)
      |> Base.encode16()
      public_hash
    end
  end
  