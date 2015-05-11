{-# LANGUAGE TemplateHaskell #-}
module Elocrypt.PasswordTest where

import Control.Monad
import Control.Monad.Random hiding (next)
import Data.Maybe
import System.Random hiding (next)
import Test.QuickCheck hiding (generate)
import Test.Tasty.QuickCheck (testProperty)
import Test.Tasty.TH

import Elocrypt.Password
import Elocrypt.Trigraph
import Elocrypt.TrigraphTest

newtype GenPassword = GenPassword (String, StdGen)

instance Show GenPassword where
  show (GenPassword s) = fst s

instance Eq GenPassword where
  (GenPassword p1) == (GenPassword p2) = fst p1 == fst p2

instance Arbitrary StdGen where
  arbitrary = mkStdGen `liftM` arbitrary

instance Arbitrary GenPassword where
  arbitrary = do
    gen <- arbitrary
    len <- suchThat arbitrary (>=6)
    return . GenPassword . generate gen $ len

tests = $(testGroupGenerator)

prop_generateShouldBeUnique :: GenPassword -> Bool
prop_generateShouldBeUnique (GenPassword (p, g))
  = p /= (fst . generate g . length $ p)

prop_generateShouldBeLong :: GenPassword -> Bool
prop_generateShouldBeLong (GenPassword p) = length (fst p) >= 6

prop_generateShouldBeSameLength :: GenPassword -> Bool
prop_generateShouldBeSameLength (GenPassword (pass, gen))
  = len == (length . fst . generate gen $ len)
  where len = length pass

prop_generateShouldConsistOfAlphabet :: GenPassword -> Bool
prop_generateShouldConsistOfAlphabet (GenPassword (p, _))
  = all ((flip elem) alphabet) p

prop_first2ShouldHaveLength2 :: StdGen -> Bool
prop_first2ShouldHaveLength2 g = length (evalRand first2 g) == 2

prop_nextShouldSkip0Weights :: TrigraphChar -> TrigraphChar -> StdGen -> Property
prop_nextShouldSkip0Weights (T c1) (T c2) gen
  = not (null frequency) ==> evalRand (next . reverse $ f2) gen `elem` (map fst frequency)
  where f2 = [c1, c2]
        frequency = filter ((/=0) . snd) . zip ['a'..'z'] . fromJust . findFrequency $ f2
