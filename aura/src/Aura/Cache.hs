{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

-- A library for working with the package cache.

{-

Copyright 2012, 2013, 2014 Colin Woodbury <colingw@gmail.com>

This file is part of Aura.

Aura is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Aura is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Aura.  If not, see <http://www.gnu.org/licenses/>.

-}

module Aura.Cache
    ( defaultPackageCache
    , cacheContents
    , cacheFilter
    , cacheMatches
    , pkgsInCache
    , alterable
    , getFilename
    , allFilenames
    , size
    , Cache
    , SimplePkg ) where

import           BasicPrelude hiding (FilePath)

import qualified Data.Map.Lazy as M
import qualified Data.Text as T

import           Aura.Monad.Aura
import           Aura.Settings.Base
import           Aura.Utils (pkgFileNameAndVer)
import           Aura.Utils.Numbers (Version)

import           Utilities (searchLinesF)
import           Shelly    (FilePath, ls)
---

type SimplePkg = (T.Text, Maybe Version)
type Cache     = M.Map SimplePkg FilePath

defaultPackageCache :: T.Text
defaultPackageCache = "/var/cache/pacman/pkg/"

simplePkg :: FilePath -> SimplePkg
simplePkg = pkgFileNameAndVer

cache :: [FilePath] -> Cache
cache = M.fromList . fmap pair
    where pair p = (simplePkg p, p)

-- This takes the filepath of the package cache as an argument.
rawCacheContents :: FilePath -> Aura [FilePath]
rawCacheContents c = filter dots <$> liftShelly (ls c)
    where dots p = p `notElem` [".", ".."]

cacheContents :: FilePath -> Aura Cache
cacheContents c = cache <$> rawCacheContents c

pkgsInCache :: [T.Text] -> Aura [T.Text]
pkgsInCache ps =
    nub . filter (`elem` ps) . allNames <$> (asks cachePathOf >>= cacheContents)

cacheMatches :: [T.Text] -> Aura [FilePath]
cacheMatches input =  searchLinesF (T.unwords input) . allFilenames <$> f
    where f :: Aura Cache
          f = asks cachePathOf >>= cacheContents

alterable :: Cache -> SimplePkg -> Bool
alterable c p = M.member p c

getFilename :: Cache -> SimplePkg -> Maybe FilePath
getFilename c p = M.lookup p c

allNames :: Cache -> [T.Text]
allNames = fmap fst . M.keys

allFilenames :: Cache -> [FilePath]
allFilenames = M.elems

size :: Cache -> Int
size = M.size

cacheFilter :: (SimplePkg -> FilePath -> Bool) -> Cache -> Cache
cacheFilter = M.filterWithKey
