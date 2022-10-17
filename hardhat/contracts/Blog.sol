// contracts/Blog.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// TODO: Support ability to mint "Post" as NFT (like Mirror Protocol)

contract Blog is Ownable {
    // Blog related details
    string public name;

    using Counters for Counters.Counter;
    Counters.Counter private _postIds;

    struct Post {
        uint256 id;
        address author;
        string title;
        string content;
        bool published;
    }

    mapping(uint256 => Post) private idToPost;
    mapping(string => Post) private ipfsHashToPost;

    // Events to be indexed by the Graph
    event PostCreated(
        uint256 id,
        address author,
        string title,
        string ipfsHash
    );
    event PostUpdated(
        uint256 id,
        address author,
        string title,
        string ipfsHash,
        bool published
    );

    constructor(string memory _name) {
        console.log("Deploying a Blog with name:", _name);
        name = _name;
    }

    function updateName(string memory _name) public onlyOwner {
        name = _name;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }

    function createPost(string memory title, string memory ipfsHash)
        public
        onlyOwner
    {
        _postIds.increment();
        uint256 postId = _postIds.current();

        Post memory post = Post(postId, msg.sender, title, ipfsHash, false);

        idToPost[postId] = post;
        ipfsHashToPost[ipfsHash] = post;

        emit PostCreated(postId, post.author, title, ipfsHash);
    }

    function updatePost(
        uint256 postId,
        string memory title,
        string memory ipfsHash,
        bool published
    ) public onlyOwner {
        Post storage post = idToPost[postId];

        require(post.id > 0, "Post not found");
        require(post.author == msg.sender, "Only author can modify their post");

        post.title = title;
        post.published = published;
        post.content = ipfsHash;

        idToPost[postId] = post;
        ipfsHashToPost[ipfsHash] = post;

        emit PostUpdated(postId, post.author, title, ipfsHash, published);
    }

    function fetchPosts() public view returns (Post[] memory) {
        uint256 numPosts = _postIds.current();

        // Dynamic array
        Post[] memory posts = new Post[](numPosts);
        for (uint256 id = 1; id <= numPosts; id++) {
            Post storage post = idToPost[id];
            posts[id - 1] = post;
        }

        return posts;
    }
}
