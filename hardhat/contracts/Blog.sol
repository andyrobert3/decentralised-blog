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
    // "postId" starts incrementing from "1"
    Counters.Counter private _postIds;

    struct Post {
        uint256 id;
        address author;
        string title;
        // IPFS hash
        string content;
        bool published;
        uint256 publishedAt;
    }

    mapping(uint256 => Post) private idToPost;
    mapping(string => Post) private ipfsHashToPost;

    modifier onlyAuthor(uint256 postId) {
        Post storage post = idToPost[postId];
        require(msg.sender == post.author, "Not post author");
        _;
    }

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
    event PostPublished(
        uint256 id,
        address author,
        string title,
        string ipfsHash
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

    // Fetch via IPFS content
    function fetchPost(string memory hash) public view returns (Post memory) {
        return ipfsHashToPost[hash];
    }

    function fetchPostsByAuthor() public view returns (Post[] memory) {
        uint256 numPosts = _postIds.current();
        uint256 numPostsByAuthor = 0;

        // Calculate "numPostsByAuthor" since memory array is static in length
        for (uint256 id = 1; id <= numPosts; id++) {
            Post memory post = idToPost[id];
            if (post.author == msg.sender) {
                numPostsByAuthor++;
            }
        }

        Post[] memory postsByAuthor = new Post[](numPostsByAuthor);
        // Create the "fetchPostsByAuthor"
        for (uint256 id = 1; id <= numPostsByAuthor; id++) {
            Post memory post = idToPost[id];
            if (post.author == msg.sender) {
                postsByAuthor[id - 1] = post;
            }
        }

        return postsByAuthor;
    }

    function createPost(string memory title, string memory ipfsHash) public {
        _postIds.increment();
        uint256 postId = _postIds.current();

        Post memory post = Post({
            id: postId,
            author: msg.sender,
            title: title,
            content: ipfsHash,
            published: false,
            publishedAt: 0
        });

        idToPost[postId] = post;
        ipfsHashToPost[ipfsHash] = post;

        emit PostCreated(postId, post.author, title, ipfsHash);
    }

    function publishPost(uint256 postId) public onlyAuthor(postId) {
        Post storage post = idToPost[postId];
        require(post.id > 0, "Post not found");

        post.publishedAt = block.timestamp;
        idToPost[postId] = post;

        emit PostPublished(postId, post.author, post.title, post.content);
    }

    function updatePost(
        uint256 postId,
        string memory title,
        string memory ipfsHash
    ) public onlyAuthor(postId) {
        Post storage post = idToPost[postId];

        require(post.id > 0, "Post not found");

        post.title = title;
        post.content = ipfsHash;

        idToPost[postId] = post;
        ipfsHashToPost[ipfsHash] = post;

        emit PostUpdated(postId, post.author, title, ipfsHash, post.published);
    }

    function fetchPosts() public view returns (Post[] memory) {
        uint256 numPosts = _postIds.current();

        // Not possible to resize memory arrays
        // Only possible to resize storage arrays
        Post[] memory posts = new Post[](numPosts);
        for (uint256 id = 1; id <= numPosts; id++) {
            Post storage post = idToPost[id];
            posts[id - 1] = post;
        }

        return posts;
    }
}
