{-|
Module:      Elocrypt.Passowrd
Description: Generate pronouncable, hard-to-guess passwords
Copyright:   (c) Sean Gillespie, 2015
License:     OtherLicense
Maintainer:  Sean Gillespie <sean@mistersg.net>
Stability:   Experimental

Generate easy-to-remember, hard-to-guess passwords
-}
module Data.Elocrypt where

import Data.Elocrypt.Trigraph

import Control.Monad
import Control.Monad.Random hiding (next)
import Data.Maybe
import System.Random hiding (next)

-- * Random password generators

-- |Generate a password using the generator g, returning the result and the
--  updated generator.
--
--  @
--  -- Generate a password of length 10 using the system generator
--  myGenPassword :: IO (String, StdGen)
--  myGenPassword = genPassword 10 True \`liftM\` getStdGen
--  @
genPassword :: RandomGen g
               => Int  -- ^ password length
               -> Bool -- ^ include capitals?
               -> g    -- ^ random generator
               -> (String, g)
genPassword len = runRand . mkPassword len

-- |Plural version of genPassword.  Generates an infinite list of passwords
--  using the generator g, returning the result and the updated generator.
--
-- @
-- -- Generate 10 passwords of length 10 using the system generator
-- myGenPasswords :: IO ([String], StdGen)
-- myGenPasswords = (\(ls, g) -> (take 10 ls, g) `liftM` genPasswords 10 True `liftM` getStdGen
-- @
genPasswords :: RandomGen g
                => Int  -- ^ password length
                -> Bool -- ^ include capitals?
                -> g    -- ^ random generator
                -> ([String], g)
genPasswords len = runRand . mkPasswords len

-- |Generate a password using the generator g, returning the result.
--
--  @
--  -- Generate a password of length 10 using the system generator
--  myNewPassword :: IO String
--  myNewPassword = newPassword 10 True \`liftM\` getStdGen
--  @
newPassword :: RandomGen g
               => Int  -- ^ password length
               -> Bool -- ^ include capitals?
               -> g    -- ^ random generator
               -> String
newPassword len = evalRand . mkPassword len

-- |Plural version of newPassword.  Generates an infinite list of passwords
--  using the generator g, returning the result
--
-- @
-- -- Generate 10 passwords of length 10 using the system generator
-- myNewPasswords :: IO [String]
-- myNewPasswords = (take 10 . genPasswords 10 True) `liftM` getStdGen
-- @
newPasswords :: RandomGen g
                => Int  -- ^ password length
                -> Bool -- ^ include capitals?
                -> g    -- ^ random generator
                -> [String]
newPasswords len = evalRand . mkPasswords len

-- |Generate a password using the MonadRandom m. MonadRandom is exposed here
--  for extra control.
--
--  @
--  -- Generate a password of length 10 using the system generator
--  myPasswords :: IO String
--  myPasswords = evalRand (mkPassword 10 True) \`liftM\` getStdGen
--  @
mkPassword :: MonadRandom m
              => Int  -- ^ password length
              -> Bool -- ^ include capitals?
              -> m String
mkPassword len caps = do
  f2 <- reverse `liftM` first2
  if len > 2
    then reverse `liftM` lastN (len - 2) f2
    else return . reverse . take len $ f2

-- |Plural version of mkPassword.  Generate an infinite list of passwords using
--  the MonadRandom m.  MonadRandom is exposed here for extra control.
--
-- @
-- -- Generate an infinite list of passwords of length 10 using the system generator
-- myMkPasswords :: IO [String]
-- myMkPasswords = evalRand (mkPasswords 10 True) \`liftM\` getStdGen
-- @
mkPasswords :: MonadRandom m
               => Int  -- ^ password length
               -> Bool -- ^ include capitals?
               -> m [String]
mkPasswords len = sequence . repeat . mkPassword len
               
-- |The alphabet we sample random values from
alphabet :: [Char]
alphabet = ['a'..'z']

-- * Internal

-- |Generate two random characters. Uses 'Elocrypt.Trigraph.trigragh'
--  to generate a weighted list.
first2 :: MonadRandom m => m String
first2 = fromList (map toWeight frequencies)
  where toWeight (s, w) = (s, sum w)

-- |Generate a random character based on the previous two characters and
--  their 'Elocrypt.Trigraph.trigraph'
next :: MonadRandom m => String -> m Char
next (x:xs:_) = fromList . zip ['a'..'z'] . fromJust . findFrequency $ [xs,x]

-- |Generate the last n characters using previous two characters
--  and their 'Elocrypt.Trigraph.trigraph'
lastN :: MonadRandom m => Int -> String -> m String
lastN 0 ls   = return ls
lastN len ls = next ls >>= lastN (len - 1) . (:ls)
